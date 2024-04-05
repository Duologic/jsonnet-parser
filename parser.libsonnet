local lexer = import './lexer.libsonnet';

{
  new(file): {
    local this = self,
    local lexicon = lexer.lex(file),

    local expmsg(expected, actual) =
      'Expected "%s" but got "%s"' % [std.toString(expected), std.toString(actual)],

    parse():
      self.parseExpr(),

    parseExpr(index=0, endTokens=[], inObject=false):
      local token = lexicon[index];

      local expr =
        if token[0] == 'IDENTIFIER'
        then self.parseIdentifier(index, endTokens, inObject)
        else if std.member(['STRING_SINGLE', 'STRING_DOUBLE'], token[0])
        then self.parseString(index, endTokens, inObject)
        else if std.member(['VERBATIM_STRING_SINGLE', 'VERBATIM_STRING_DOUBLE'], token[0])
        then self.parseVerbatimString(index, endTokens, inObject)
        else if token[0] == 'STRING_BLOCK'
        then self.parseTextBlock(index, endTokens, inObject)
        else if token[0] == 'NUMBER'
        then self.parseNumber(index, endTokens, inObject)
        else if token[1] == '{'
        then self.parseObject(index, endTokens, inObject)
        else if token[1] == '['
        then self.parseArray(index, endTokens, inObject)
        else if token[1] == 'super'
        then self.parseSuper(index, endTokens, inObject)
        else if token[1] == 'local'
        then self.parseLocalBind(index, endTokens, inObject)
        else if token[1] == 'if'
        then self.parseConditional(index, endTokens, inObject)
        else if token[0] == 'OPERATOR'
        then self.parseUnary(index, endTokens, inObject)
        else if token[1] == 'function'
        then self.parseAnonymousFunction(index, endTokens, inObject)
        else if token[1] == 'assert'
        then self.parseAssertionExpr(index, endTokens, inObject)
        else if std.member(['importstr', 'importbin', 'import'], token[1])
        then self.parseImport(index, endTokens, inObject)
        else if token[1] == 'error'
        then self.parseErrorExpr(index, endTokens, inObject)
        else if token[1] == '('
        then self.parseParenthesis(index, endTokens, inObject)
        else error 'Unexpected token: "%s"' % std.toString(token);


      local parseRemainder(obj) =
        if obj.cursor == std.length(lexicon)
           || std.member(endTokens, lexicon[obj.cursor][1])
        then obj
        else
          local token = lexicon[obj.cursor];
          local expr =
            if token[1] == '.'
            then self.parseFieldaccess(obj, endTokens, inObject)
            else if token[1] == '['
            then self.parseIndexing(obj, endTokens, inObject)
            else if token[1] == '('
            then self.parseFunctioncall(obj, endTokens, inObject)
            else if token[1] == '{'
            then self.parseImplicitPlus(obj, endTokens, inObject)
            else if lexicon[obj.cursor][1] == 'in' && lexicon[obj.cursor + 1][1] == 'super'
            then self.parseExprInSuper(obj, endTokens, inObject)
            else if token[0] == 'OPERATOR' && std.member(binaryoperators, token[1])
            then self.parseBinary(obj, endTokens, inObject)
            else error 'Unexpected token: "%s"' % std.toString(token);
          parseRemainder(expr);

      parseRemainder(expr),

    parseIdentifier(index, endTokens=[], inObject=false):
      local token = lexicon[index];
      local tokenValue = token[1];
      local literals = {
        'null': null,
        'true': true,
        'false': false,
        'self': 'self',
        '$': '$',
      };
      if std.member(std.objectFields(literals), tokenValue)
      then {
        type: 'literal',
        literal: literals[tokenValue],
        cursor:: index + 1,
      }
      else {
        type: 'id',
        id: tokenValue,
        cursor:: index + 1,
      },

    parseString(index, endTokens, inObject):
      local token = lexicon[index];
      local tokenValue = token[1];
      local expected = ['STRING_SINGLE', 'STRING_DOUBLE'];
      assert std.member(expected, token[0]) : expmsg(expected, token);
      {
        type: 'string',
        string: tokenValue[1:std.length(tokenValue) - 1],
        cursor:: index + 1,
      },

    parseVerbatimString(index, endTokens, inObject):
      local token = lexicon[index];
      local tokenValue = token[1];
      local expected = ['VERBATIM_STRING_SINGLE', 'VERBATIM_STRING_DOUBLE'];
      assert std.member(expected, token[0]) : expmsg(expected, token);
      {
        type: 'string',
        string: tokenValue[2:std.length(tokenValue) - 1],
        verbatim: true,
        cursor:: index + 1,
      },

    parseTextBlock(index, endTokens, inObject):
      local token = lexicon[index];
      local tokenValue = token[1];
      assert token[0] == 'STRING_BLOCK' : expmsg('STRING_BLOCK', token);

      local lines = std.split(tokenValue, '\n');
      local spacesOnFirstLine = std.length(lines[1]) - std.length(std.lstripChars(lines[1], ' '));
      local string = std.join('\n', [
        line[spacesOnFirstLine:]
        for line in lines[1:std.length(lines) - 1]
      ]);
      {
        type: 'string',
        string: string,
        textblock: true,
        cursor:: index + 1,
      },

    parseNumber(index, endTokens, inObject):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'number',
        number: tokenValue,
        cursor:: index + 1,
      },

    local binaryoperators = [
      '*',
      '/',
      '%',
      '+',
      '-',
      '<<',
      '>>',
      '<',
      '<=',
      '>',
      '>=',
      '==',
      '!=',
      'in',
      '&',
      '^',
      '|',
      '&&',
      '||',
    ],

    parseBinary(expr, endTokens=[], inObject):
      local index = expr.cursor;
      local leftExpr = expr;
      local binaryop = lexicon[index];
      assert std.member(binaryoperators, binaryop[1]) : 'Not a binary operator: ' + binaryop[1];
      local rightExpr = self.parseExpr(index + 1, endTokens, inObject);
      {
        type: 'binary',
        binaryop: binaryop[1],
        left_expr: leftExpr,
        right_expr: rightExpr,
        cursor:: rightExpr.cursor,
      },

    parseUnary(index, endTokens, inObject):
      local token = lexicon[index];
      local unaryoperators = [
        '-',
        '+',
        '!',
        '~',
      ];
      assert std.member(unaryoperators, token[1]) : 'Not a unary operator: ' + token[1];
      local expr = self.parseExpr(index + 1, endTokens, inObject);
      {
        type: 'unary',
        unaryop: token[1],
        expr: expr,
        cursor:: expr.cursor,
      },

    local parseTokens(index, endTokens, splitToken, parseF) =
      local split = if std.isArray(splitToken) then splitToken else [splitToken];
      local infunc(index) =
        local token = lexicon[index][1];
        local item = parseF(index);
        local nextToken = lexicon[item.cursor];

        if std.member(endTokens, token)
        then []
        else if std.member(endTokens, nextToken[1])
        then [item]
        else if std.member(split, nextToken[1])
        then [item { cursor+:: 1 }]
             + infunc(item.cursor + 1)
        else error 'Expected %s before next item but got "%s"' % [split, item];
      infunc(index),

    parseObject(index, endTokens, inObject):
      local endTokens = ['}'];
      local inObject = true;

      local token = lexicon[index];
      assert token[1] == '{' : expmsg('{', token);

      local memberEndtokens = endTokens + ['for'];
      local members =
        parseTokens(
          index + 1,
          memberEndtokens,
          ',',
          function(index)
            self.parseMember(index, memberEndtokens + [','], inObject)
        );

      local last = std.reverse(members)[0];
      local nextCursor =
        if std.length(members) > 0
        then last.cursor
        else index + 1;

      local isForloop = (lexicon[nextCursor][1] == 'for');
      local forspec = self.parseForspec(nextCursor, endTokens + ['for', 'if'], inObject);

      local fields = std.filter(function(member) member.type == 'field' || member.type == 'field_function', members);
      local asserts = std.filter(function(member) member.type == 'assertion', members);

      assert !(isForloop && std.length(asserts) != 0) : 'Object comprehension cannot have asserts';
      assert !(isForloop && std.length(fields) > 1) : 'Object comprehension can only have one field';
      assert !(isForloop && fields[0].fieldname.type != 'fieldname_expr') : 'Object comprehension can only have [e] fields';
      assert !(isForloop && std.get(fields[0], 'additive', false)) : 'Object comprehension field can not be [e]+ (additive)';

      local fieldIndex = std.prune(std.mapWithIndex(function(i, m) if m == fields[0] then i else null, members))[0];
      local leftObjectLocals = members[:fieldIndex];
      local rightObjectLocals = members[fieldIndex + 1:];

      local hasCompspec = std.member(['for', 'if'], lexicon[forspec.cursor][1]);
      local compspec = self.parseCompspec(forspec.cursor, endTokens, inObject);

      local cursor =
        if isForloop
        then
          if hasCompspec
          then compspec.cursor
          else forspec.cursor
        else nextCursor;

      assert lexicon[cursor][1] == '}' : expmsg('}', lexicon[cursor]);

      if isForloop
      then {
        type: 'object_forloop',
        forspec: forspec,
        [if hasCompspec then 'compspec']: compspec,
        field: fields[0],
        [if std.length(leftObjectLocals) > 0 then 'left_object_locals']: leftObjectLocals,
        [if std.length(rightObjectLocals) > 0 then 'right_object_locals']: rightObjectLocals,
        cursor:: cursor + 1,
      }
      else {
        type: 'object',
        members: members,
        cursor:: cursor + 1,
      },

    parseArray(index, endTokens, inObject):
      local endTokens = [']'];

      local token = lexicon[index];
      assert token[1] == '[' : expmsg('[', token);

      local itemEndtokens = endTokens + ['for'];
      local items =
        parseTokens(
          index + 1,
          itemEndtokens,
          ',',
          function(index)
            self.parseExpr(index, itemEndtokens + [','], inObject)
        );

      local last = std.reverse(items)[0];
      local nextCursor =
        if std.length(items) > 0
        then last.cursor
        else index + 1;

      local isForloop = (lexicon[nextCursor][1] == 'for');
      local forspec = self.parseForspec(nextCursor, endTokens + ['for', 'if'], inObject);

      assert !(isForloop && std.length(items) > 1) : 'Array forloop can only have one expression';

      local hasCompspec = std.member(['for', 'if'], lexicon[forspec.cursor][1]);
      local compspec = self.parseCompspec(forspec.cursor, [']'], inObject);

      local cursor =
        if isForloop
        then
          if hasCompspec
          then compspec.cursor
          else forspec.cursor
        else nextCursor;

      assert lexicon[cursor][1] == ']' : expmsg(']', lexicon[cursor]);

      if isForloop
      then {
        type: 'forloop',
        expr: items[0],
        forspec: forspec,
        [if hasCompspec then 'compspec']: compspec,
        cursor:: cursor + 1,
      }
      else {
        type: 'array',
        items: items,
        cursor:: cursor + 1,
      },

    parseFieldaccess(obj, endTokens, inObject):
      local token = lexicon[obj.cursor];
      assert token[1] == '.' : expmsg('.', token);
      local id = self.parseIdentifier(obj.cursor + 1, endTokens, inObject);
      {
        type: 'fieldaccess',
        exprs: [obj],
        id: id,
        cursor:: id.cursor,
      },

    parseIndexing(obj, endTokens, inObject):
      local endTokens = [']'];
      assert lexicon[obj.cursor][1] == '[' : expmsg('[', lexicon[obj.cursor]);
      local literal(cursor) = {
        type: 'literal',
        literal: '',
        cursor:: cursor,
      };
      local parseExprs(index) =
        local token = lexicon[index];
        local prevToken = lexicon[index - 1];
        local expr = self.parseExpr(index, endTokens + [':', '::'], inObject);
        if token[1] == ']'
        then []
        else if token[1] == ':' && prevToken[0] != 'OPERATOR'
        then [literal(index + 1)] + parseExprs(index + 1)
        else if token[1] == '::' && prevToken[0] != 'OPERATOR'
        then [literal(index + 1), literal(index + 1)] + parseExprs(index + 1)
        else [expr] + parseExprs(expr.cursor);

      local exprs = parseExprs(obj.cursor + 1);

      assert std.length(exprs) != 0 : 'Indexing requires an expression';

      local last = std.reverse(exprs)[0];
      local cursor =
        if std.length(exprs) > 0
        then last.cursor
        else obj.cursor + 1;

      assert lexicon[cursor][1] == ']' : expmsg(']', lexicon[cursor]);
      {
        type: 'indexing',
        expr: obj,
        exprs: exprs,
        cursor:: cursor + 1,
      },

    parseSuper(index, endTokens, inObject):
      assert lexicon[index][1] == 'super' : expmsg('super', lexicon[index]);
      assert inObject : "Can't use super outside of an object";
      local token = lexicon[index + 1];
      if token[1] == '.'
      then
        local id = self.parseIdentifier(index + 2, endTokens, inObject);
        {
          type: 'fieldaccess_super',
          id: id,
          cursor:: id.cursor,
        }
      else if token[1] == '['
      then
        local endTokens = [']'];
        local expr = self.parseExpr(index + 2, endTokens, inObject);
        assert lexicon[expr.cursor][1] == ']' : expmsg(']', lexicon[expr.cursor]);
        {
          type: 'indexing_super',
          expr: expr,
          cursor:: expr.cursor + 1,
        }
      else error expmsg(['.', '['], token),

    parseFunctioncall(obj, endTokens, inObject):
      assert lexicon[obj.cursor][1] == '(' : expmsg('(', lexicon[obj.cursor]);

      local args =
        parseTokens(
          obj.cursor + 1,
          [')'],
          [','],
          function(index)
            self.parseArg(index, endTokens, inObject),
        );

      local validargs =
        std.foldl(
          function(acc, arg)
            assert !(std.length(acc) > 0
                     && 'id' in std.reverse(acc)[0]
                     && !('id' in arg))
                   : 'Positional argument after a named argument is not allowed';
            acc + [arg],
          args,
          []
        );

      local last = std.reverse(args)[0];
      local cursor =
        if std.length(args) > 0
        then last.cursor
        else obj.cursor + 1;

      assert lexicon[cursor][1] == ')' : expmsg(')', lexicon[cursor]);
      {
        type: 'functioncall',
        expr: obj,
        args: validargs,
        cursor:: cursor + 1,
      },

    parseArg(index, endTokens, inObject):
      local endTokens = [',', ')'];
      local expr = self.parseExpr(index, endTokens + ['='], inObject);
      local hasExpr = (lexicon[expr.cursor][1] == '=');
      local id = self.parseIdentifier(index, endTokens, inObject);
      local exprValue = self.parseExpr(id.cursor + 1, endTokens, inObject);
      {
        type: 'arg',
        expr: expr,
        cursor:: expr.cursor,
      }
      + (if hasExpr
         then {
           id: id,
           expr: exprValue,
           cursor:: exprValue.cursor,
         }
         else {}),

    parseLocalBind(index, endTokens, inObject):
      local bindEndTokens = [';'];
      assert lexicon[index][1] == 'local' : expmsg('local', lexicon[index]);
      local binds =
        parseTokens(
          index + 1,
          bindEndTokens,
          ',',
          function(index)
            self.parseBind(index, bindEndTokens + [','], inObject)
        );
      local last = std.reverse(binds)[0];
      assert lexicon[last.cursor][1] == ';' : expmsg(';', lexicon[last.cursor]);
      local expr = self.parseExpr(last.cursor + 1, endTokens, inObject);
      {
        type: 'local_bind',
        bind: binds[0],
        expr: expr,
        [if std.length(binds) > 1 then 'additional_binds']: binds[1:],
        cursor:: expr.cursor,
      },

    parseConditional(index, endTokens, inObject):
      assert lexicon[index][1] == 'if' : expmsg('if', lexicon[index]);
      local ifExpr = self.parseExpr(index + 1, ['then'], inObject);

      assert lexicon[ifExpr.cursor][1] == 'then' : expmsg('then', lexicon[ifExpr.cursor]);
      local thenExpr = self.parseExpr(ifExpr.cursor + 1, ['else'] + endTokens, inObject);

      local hasElseExpr = (lexicon[thenExpr.cursor][1] == 'else');
      local elseExpr = self.parseExpr(thenExpr.cursor + 1, endTokens, inObject);

      local cursor =
        if hasElseExpr
        then elseExpr.cursor
        else thenExpr.cursor;
      {
        type: 'conditional',
        if_expr: ifExpr,
        then_expr: thenExpr,
        [if hasElseExpr then 'else_expr']: elseExpr,
        cursor:: cursor,
      },

    parseImplicitPlus(obj, endTokens, inObject):
      local object = self.parseObject(obj.cursor, endTokens, inObject);
      {
        type: 'implicit_plus',
        expr: obj,
        object: object,
        cursor:: object.cursor,
      },

    parseAnonymousFunction(index, endTokens, inObject):
      assert lexicon[index][1] == 'function' : expmsg('function', lexicon[index]);
      local params = self.parseParams(index + 1, endTokens, inObject);
      local expr = self.parseExpr(params.cursor, endTokens, inObject);
      {
        type: 'anonymous_function',
        params: params,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseAssertionExpr(index, endTokens, inObject):
      local assertionEndToken = ';';
      local assertion = self.parseAssertion(index, [assertionEndToken], inObject);
      assert lexicon[assertion.cursor][1] == assertionEndToken : expmsg(assertionEndToken, lexicon[assertion.cursor]);
      local expr = self.parseExpr(assertion.cursor + 1, endTokens, inObject);
      {
        type: 'assertion_expr',
        assertion: assertion,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseImport(index, endTokens, inObject):
      local token = lexicon[index];
      local possibleValues = ['importstr', 'importbin', 'import'];
      assert std.member(possibleValues, token[1]) : expmsg(possibleValues, token);
      assert !std.startsWith(lexicon[index + 1][0], 'STRING_BLOCK') : 'Block string literal not allowed for imports';
      local path =
        local token = lexicon[index + 1];
        if std.member(['STRING_SINGLE', 'STRING_DOUBLE'], token[0])
        then self.parseString(index + 1, endTokens, inObject)
        else if std.member(['VERBATIM_STRING_SINGLE', 'VERBATIM_STRING_DOUBLE'], token[0])
        then self.parseVerbatimString(index + 1, endTokens, inObject)
        else error 'Unexpected token: "%s"' % std.toString(lexicon[index + 1]);
      {
        type: token[1] + '_statement',
        path: path.string,
        cursor:: path.cursor,
      },

    parseErrorExpr(index, endTokens, inObject):
      assert lexicon[index][1] == 'error' : expmsg('error', lexicon[index]);
      local expr = self.parseExpr(index + 1, endTokens, inObject);
      {
        type: 'error_expr',
        expr: expr,
        cursor:: expr.cursor,
      },

    parseExprInSuper(obj, endTokens, inObject):
      assert inObject : "Can't use super outside of an object";
      assert lexicon[obj.cursor][1] == 'in'
             && lexicon[obj.cursor + 1][1] == 'super'
             : expmsg('in super', [lexicon[obj.cursor], lexicon[obj.cursor + 1]]);
      {
        type: 'expr_in_super',
        expr: obj,
        cursor:: obj.cursor + 2,
      },

    parseParenthesis(index, endTokens, inObject):
      assert lexicon[index][1] == '(' : expmsg('(', lexicon[index]);
      local expr = self.parseExpr(index + 1, [')'], inObject);
      assert lexicon[expr.cursor][1] == ')' : expmsg(')', lexicon[expr.cursor]);
      {
        type: 'parenthesis',
        expr: expr,
        cursor:: expr.cursor + 1,
      },

    parseMember(index, endTokens, inObject):
      local token = lexicon[index];
      if token[1] == 'local'
      then self.parseObjectLocal(index, endTokens, inObject)
      else if token[1] == 'assert'
      then self.parseAssertion(index, endTokens, inObject)
      else self.parseField(index, endTokens, inObject),

    parseObjectLocal(index, endTokens, inObject):
      local token = lexicon[index];
      assert token[1] == 'local' : expmsg('local', token);
      local bind = self.parseBind(index + 1, endTokens, inObject=true);
      {
        type: 'object_local',
        bind: bind,
        cursor:: bind.cursor,
      },

    parseBind(index, endTokens, inObject):
      local id = self.parseIdentifier(index, endTokens, inObject);

      local isFunction = (lexicon[id.cursor][1] == '(');
      local params = self.parseParams(id.cursor, endTokens, inObject);

      local nextCursor =
        if isFunction
        then params.cursor
        else id.cursor;

      assert lexicon[nextCursor][1] == '=' : expmsg('=', lexicon[nextCursor]);

      local expr = self.parseExpr(nextCursor + 1, endTokens, inObject);
      if isFunction
      then {
        type: 'bind_function',
        id: id,
        expr: expr,
        params: params,
        cursor:: expr.cursor,
      }
      else {
        type: 'bind',
        id: id,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseAssertion(index, endTokens, inObject):
      assert lexicon[index][1] == 'assert' : expmsg('assert', lexicon[index]);
      local expr = self.parseExpr(index + 1, [':'] + endTokens, inObject);

      local hasReturnExpr = lexicon[expr.cursor][1] == ':';
      local returnExpr = self.parseExpr(expr.cursor + 1, endTokens, inObject);

      local cursor =
        if hasReturnExpr
        then returnExpr.cursor
        else expr.cursor;

      assert std.member(endTokens, lexicon[cursor][1]) : expmsg(std.join(',', endTokens), lexicon[cursor]);
      {
        type: 'assertion',
        expr: expr,
        [if hasReturnExpr then 'return_expr']: returnExpr,
        cursor:: cursor,
      },

    parseField(index, endTokens, inObject):
      local fieldname = self.parseFieldname(index, endTokens, inObject);

      local isFunction = (lexicon[fieldname.cursor][1] == '(');
      local params = self.parseParams(fieldname.cursor, endTokens, inObject);

      local nextCursor =
        if isFunction
        then params.cursor
        else fieldname.cursor;

      local operator = lexicon[nextCursor][1];
      local expectOp = [':', '::', ':::', '+:', '+::', '+:::'];
      assert std.member(expectOp, operator) : expmsg(std.join('","', expectOp), lexicon[nextCursor]);

      local additive = std.startsWith(operator, '+');
      local h =
        if additive
        then operator[1:]
        else operator;

      local expr = self.parseExpr(nextCursor + 1, endTokens, inObject);
      {
        type: 'field',
        fieldname: fieldname,
        [if additive then 'additive']: additive,
        h: h,
        expr: expr,
        cursor:: expr.cursor,
      }
      + (if isFunction
         then {
           type: 'field_function',
           params: params,
         }
         else {}),

    parseFieldname(index, endTokens, inObject):
      local token = lexicon[index];
      if token[0] == 'IDENTIFIER'
      then self.parseIdentifier(index, endTokens, inObject)
      else if std.member(['STRING_SINGLE', 'STRING_DOUBLE'], token[0])
      then self.parseString(index, endTokens, inObject)
      else if std.member(['VERBATIM_STRING_SINGLE', 'VERBATIM_STRING_DOUBLE'], token[0])
      then self.parseVerbatimString(index, endTokens, inObject)
      else if token[0] == 'STRING_BLOCK'
      then self.parseTextBlock(index, endTokens, inObject)
      else if token[1] == '['
      then self.parseFieldnameExpr(index, endTokens, inObject)
      else error 'Unexpected token: "%s"' % std.toString(token),

    parseFieldnameExpr(index, endTokens, inObject):
      local token = lexicon[index];
      assert token[1] == '[' : expmsg('[', token);
      local expr = self.parseExpr(index + 1, [']'], inObject);
      assert lexicon[expr.cursor][1] == ']' : expmsg(']', lexicon[expr.cursor]);
      {
        type: 'fieldname_expr',
        expr: expr,
        cursor:: expr.cursor + 1,
      },

    parseParams(index, endTokens, inObject):
      local token = lexicon[index];
      assert token[1] == '(' : expmsg('(', token);
      local params = parseTokens(
        index + 1,
        [')'],
        ',',
        function(index)
          self.parseParam(index, endTokens, inObject)
      );
      local last = std.reverse(params)[0];
      local cursor =
        if std.length(params) > 0
        then last.cursor
        else index + 1;
      assert lexicon[cursor][1] == ')' : expmsg(')', lexicon[cursor]);
      {
        type: 'params',
        params: params,
        cursor:: cursor + 1,
      },

    parseParam(index, endTokens, inObject):
      local endTokens = [',', ')'];
      local id = self.parseExpr(index, endTokens + ['='], inObject);
      local hasExpr = lexicon[id.cursor][1] == '=';
      local expr = self.parseExpr(id.cursor + 1, endTokens, inObject);
      local cursor =
        if hasExpr
        then expr.cursor
        else id.cursor;
      {
        type: 'param',
        id: id,
        [if hasExpr then 'expr']: expr,
        cursor:: cursor,
      },

    parseForspec(index, endTokens, inObject):
      local token = lexicon[index];
      assert token[1] == 'for' : expmsg('for', token);
      local id = self.parseIdentifier(index + 1, ['in'], inObject);
      assert lexicon[id.cursor][1] == 'in' : expmsg('in', lexicon[id.cursor]);
      local expr = self.parseExpr(id.cursor + 1, endTokens, inObject);
      {
        type: 'forspec',
        id: id,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseIfspec(index, endTokens, inObject):
      local token = lexicon[index];
      assert token[1] == 'if' : expmsg('if', token);
      local expr = self.parseExpr(index + 1, endTokens, inObject);
      {
        type: 'ifspec',
        expr: expr,
        cursor:: expr.cursor,
      },

    parseCompspec(index, endTokens, inObject):
      local items =
        parseTokens(
          // Doing funky index juggling because parseTokens moves cursor past splitToken
          index + 1,
          endTokens,
          ['for', 'if'],
          function(index)
            local token = lexicon[index - 1];
            if std.member(endTokens, token[1])
            then { cursor: index }
            else
              if token[1] == 'for'
              then self.parseForspec(index - 1, endTokens + ['for', 'if'], inObject)
              else if token[1] == 'if'
              then self.parseIfspec(index - 1, endTokens + ['for', 'if'], inObject)
              else error expmsg(['for', 'if'], token)
        );
      local last = std.reverse(items)[0];
      {
        type: 'compspec',
        items: items,
        cursor:: last.cursor,
      },
  },
}
