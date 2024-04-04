local lexer = import './lexer.libsonnet';

{
  new(file): {
    local this = self,
    local lexicon = lexer.lex(file),

    local lexMap = {
      IDENTIFIER: this.parseIdentifier,
      NUMBER: this.parseNumber,
      STRING_SINGLE: this.parseString,
      STRING_DOUBLE: this.parseString,
      VERBATIM_STRING_SINGLE: this.parseVerbatimString,
      VERBATIM_STRING_DOUBLE: this.parseVerbatimString,
      STRING_BLOCK: this.parseTextBlock,
      OPERATOR: this.parseUnary,
      SYMBOL: this.parseSymbol,
    },

    local symbolMap = {
      '{': this.parseObject,
      '[': this.parseArray,
      '(': this.parseParenthesis,
    },

    local symbolRemainderMap = {
      '.': this.parseFieldaccess,
      '[': this.parseIndexing,
      '(': this.parseFunctioncall,
      '{': this.parseImplicitPlus,
    },

    parse():
      local token = lexicon[0];
      local expr = self.parseExpr();
      if expr.cursor == std.length(lexicon)
      then expr
      else lexicon[expr.cursor:],

    parseExpr(index=0, endTokens=[], inObject=false):
      local token = lexicon[index];
      local expr =
        (if token[0] == 'OPERATOR'
         then self.parseUnary(index, endTokens, inObject)
         else if token[1] == 'local'
         then self.parseLocalBind(index, endTokens)
         else if token[1] == 'super'
         then self.parseSuper(index, inObject)
         else if token[1] == 'if'
         then self.parseConditional(index, endTokens, inObject)
         else if token[1] == 'function'
         then self.parseAnonymousFunction(index, endTokens, inObject)
         else if token[1] == 'assert'
         then self.parseAssertionExpr(index, endTokens, inObject)
         else if std.member(['importstr', 'importbin', 'import'], token[1])
         then self.parseImport(index)
         else if token[1] == 'error'
         then self.parseErrorExpr(index, endTokens, inObject)
         else self.parseLex(index));

      self.parseExprRemainder(expr, endTokens, inObject),

    parseExprRemainder(obj, endTokens, inObject):
      if obj.cursor == std.length(lexicon)
         || std.member(endTokens, lexicon[obj.cursor][1])
      then obj
      else
        local token = lexicon[obj.cursor];
        local expr =
          (if lexicon[obj.cursor][1] == 'in' && lexicon[obj.cursor + 1][1] == 'super'
           then self.parseExprInSuper(obj, inObject)
           else if token[0] == 'OPERATOR' && std.member(binaryoperators, token[1])
           then self.parseBinary(obj, endTokens)
           else getParseFunction(
             symbolRemainderMap,
             token[1],
             function(o) error 'Unexpected token: ' + std.toString(lexicon[o.cursor])
           )(obj));
        self.parseExprRemainder(expr, endTokens, inObject),

    local getParseFunction(map, key, default=function(i) error 'Unexpected token: ' + std.toString(lexicon[i])) =
      std.get(map, key, default),

    parseLex(index):
      getParseFunction(lexMap, lexicon[index][0])(index),

    parseSymbol(index):
      getParseFunction(symbolMap, lexicon[index][1])(index),

    parseIdentifier(index):
      local token = lexicon[index];
      local tokenValue = token[1];
      local literals = {
        'null': null,
        'true': true,
        'false': false,
        'self': 'self',
        '$': '$',  // FIXME: is not seen as identifier
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

    parseNumber(index):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'number',
        number: tokenValue,
        cursor:: index + 1,
      },

    parseString(index):
      local token = lexicon[index];
      local tokenValue = token[1];
      {
        type: 'string',
        string: tokenValue[1:std.length(tokenValue) - 1],
        cursor:: index + 1,
      },

    parseVerbatimString(index):
      local token = lexicon[index];
      local tokenValue = token[1];

      assert
        token[0] == 'VERBATIM_STRING_SINGLE'
        || token[0] == 'VERBATIM_STRING_DOUBLE'
        : 'Expected VERBATIM_STRING_SINGLE or VERBATIM_STRING_DOUBLE but got '
          + std.toString(token);

      {
        type: 'string',
        string: tokenValue[2:std.length(tokenValue) - 1],
        verbatim: true,
        cursor:: index + 1,
      },

    parseTextBlock(index):
      local token = lexicon[index];

      assert
        token[0] == 'STRING_BLOCK'
        : 'Expected STRING_BLOCK but got '
          + std.toString(token);

      local tokenValue = token[1];

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

    parseBinary(expr, endTokens=[]):
      local index = expr.cursor;
      local leftExpr = expr;
      local binaryop = lexicon[index];
      assert std.member(binaryoperators, binaryop[1]) : 'Not a binary operator: ' + binaryop[1];
      local rightExpr = self.parseExpr(index + 1, endTokens);
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
        then [item + { cursor+:: 1 }]
             + infunc(item.cursor + 1)
        else error 'Expected %s before next item but got "%s"' % [split, item];
      infunc(index),

    parseObject(index):
      local token = lexicon[index];

      assert token[1] == '{' : 'Expected { but got ' + token[1];

      local memberEndtokens = ['}', 'for', 'if'];
      local members = parseTokens(
        index + 1,
        memberEndtokens,
        ',',
        function(index)
          self.parseMember(index, [','] + memberEndtokens)
      );

      local last = std.reverse(members)[0];
      local nextCursor =
        if std.length(members) > 0
        then last.cursor
        else index + 1;

      local isForloop = (lexicon[nextCursor][1] == 'for');
      local forspec = self.parseForspec(nextCursor, ['}', 'for', 'if']);

      local fields = std.filter(function(member) member.type == 'field' || member.type == 'field_function', members);
      local asserts = std.filter(function(member) member.type == 'assertion', members);

      assert !(isForloop && std.length(asserts) != 0) : 'Object comprehension cannot have asserts';
      assert !(isForloop && std.length(fields) > 1) : 'Object comprehension can only have one field';
      assert !(isForloop && fields[0].fieldname.type != 'fieldname_expr') : 'Object comprehension can only have [e] fields';

      local fieldIndex = std.prune(std.mapWithIndex(function(i, m) if m == fields[0] then i else null, members))[0];
      local leftObjectLocals = members[:fieldIndex];
      local rightObjectLocals = members[fieldIndex + 1:];

      local hasCompspec = std.member(['for', 'if'], lexicon[forspec.cursor][1]);
      local compspec = self.parseCompspec(forspec.cursor, ['}']);

      local cursor =
        if isForloop
        then
          if hasCompspec
          then compspec.cursor
          else forspec.cursor
        else nextCursor;

      assert lexicon[cursor][1] == '}' : 'Expected } but got ' + lexicon[cursor][1];

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

    parseArray(index):
      local token = lexicon[index];

      assert token[1] == '[' : 'Expected [ but got ' + token[1];

      local itemEndtokens = [']', 'for', 'if'];
      local items = parseTokens(
        index + 1,
        itemEndtokens,
        ',',
        function(index)
          self.parseExpr(index, [','] + itemEndtokens)
      );

      local last = std.reverse(items)[0];
      local nextCursor =
        if std.length(items) > 0
        then last.cursor
        else index + 1;

      local isForloop = (lexicon[nextCursor][1] == 'for');
      local forspec = self.parseForspec(nextCursor, [']', 'for', 'if']);

      assert !(isForloop && std.length(items) > 1) : 'Array forloop can only have one expression';

      local hasCompspec = std.member(['for', 'if'], lexicon[forspec.cursor][1]);
      local compspec = self.parseCompspec(forspec.cursor, [']']);

      local cursor =
        if isForloop
        then
          if hasCompspec
          then compspec.cursor
          else forspec.cursor
        else nextCursor;

      assert lexicon[cursor][1] == ']' : 'Expected ] but got ' + lexicon[cursor][1];

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

    parseFieldaccess(obj):
      local token = lexicon[obj.cursor];
      assert token[1] == '.' : 'Expected "." but got "%s"' % token[1];
      local id = self.parseIdentifier(obj.cursor + 1);
      {
        type: 'fieldaccess',
        exprs: [obj],
        id: id,
        cursor:: id.cursor,
      },

    parseIndexing(obj):
      assert lexicon[obj.cursor][1] == '[' : 'Expected [ but got ' + lexicon[obj.cursor][1];
      local literal(cursor) = {
        type: 'literal',
        literal: '',
        cursor:: cursor,
      };
      local f(index) =
        local token = lexicon[index];
        local prevToken = lexicon[index - 1];
        local expr = self.parseExpr(index, [':', '::', ']']);
        if token[1] == ']'
        then []
        else if token[1] == ':' && prevToken[0] != 'OPERATOR'
        then [literal(index + 1)] + f(index + 1)
        else if token[1] == '::' && prevToken[0] != 'OPERATOR'
        then [literal(index + 1), literal(index + 1)] + f(index + 1)
        else [expr] + f(expr.cursor);

      local exprs = f(obj.cursor + 1);

      assert std.length(exprs) != 0 : 'Indexing requires an expression';

      local last = std.reverse(exprs)[0];
      local cursor =
        if std.length(exprs) > 0
        then last.cursor
        else obj.cursor + 1;

      assert lexicon[cursor][1] == ']' : 'Expected ] but got ' + lexicon[cursor][1];
      {
        type: 'indexing',
        expr: obj,
        exprs: exprs,
        cursor:: cursor + 1,
      },

    parseSuper(index, inObject):
      assert lexicon[index][1] == 'super' : 'Expected super but got ' + lexicon[index][1];
      local map = {
        '.': this.parseFieldaccessSuper,
        '[': this.parseIndexingSuper,
      };

      map[lexicon[index + 1][1]](index, inObject),

    parseFieldaccessSuper(index, inObject):
      assert lexicon[index][1] == 'super' : 'Expected super but got ' + lexicon[index][1];
      assert lexicon[index + 1][1] == '.' : 'Expected "." but got ' + lexicon[index + 1][1];
      assert inObject : "Can't use super outside of an object";
      local id = self.parseIdentifier(index + 2);
      {
        type: 'fieldaccess_super',
        id: id,
        cursor:: id.cursor,
      },

    parseIndexingSuper(index, inObject):
      assert lexicon[index][1] == 'super' : 'Expected super but got ' + lexicon[index][1];
      assert lexicon[index + 1][1] == '[' : 'Expected "[" but got ' + lexicon[index + 1][1];
      assert inObject : "Can't use super outside of an object";
      local expr = self.parseExpr(index + 2, [']']);
      assert lexicon[expr.cursor][1] == ']' : 'Expected "]" but got ' + lexicon[expr.cursor][1];
      {
        type: 'indexing_super',
        expr: expr,
        cursor:: expr.cursor + 1,
      },

    parseFunctioncall(obj):
      assert lexicon[obj.cursor][1] == '(' : 'Expected ( but got ' + lexicon[obj.cursor][1];

      local args =
        parseTokens(
          obj.cursor + 1,
          [')'],
          [','],
          self.parseArg,
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

      assert lexicon[cursor][1] == ')' : 'Expected ")" but got "%s"' % lexicon[cursor][1];

      {
        type: 'functioncall',
        expr: obj,
        args: validargs,
        cursor:: cursor + 1,
      },

    parseArg(index):
      local endTokens = [',', ')'];
      local expr = self.parseExpr(index, endTokens + ['=']);
      local hasExpr = (lexicon[expr.cursor][1] == '=');
      local id = self.parseIdentifier(index);
      local exprValue = self.parseExpr(id.cursor + 1, endTokens);
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

    parseLocalBind(index, endTokens):
      assert lexicon[index][1] == 'local' : 'Expected local but got ' + lexicon[index][1];
      local binds =
        parseTokens(
          index + 1,
          [';'],
          ',',
          function(index)
            self.parseBind(index, [',', ';'])
        );
      local last = std.reverse(binds)[0];
      assert lexicon[last.cursor][1] == ';' : 'Expected ; but got ' + lexicon[last.cursor][1];
      local expr = self.parseExpr(last.cursor + 1, endTokens);
      {
        type: 'local_bind',
        bind: binds[0],
        expr: expr,
        [if std.length(binds) > 1 then 'additional_binds']: binds[1:],
        cursor:: expr.cursor,
      },

    parseConditional(index, endTokens, inObject):
      assert lexicon[index][1] == 'if' : 'Expected if but got ' + lexicon[index][1];
      local ifExpr = self.parseExpr(index + 1, ['then'], inObject);

      assert lexicon[ifExpr.cursor][1] == 'then' : 'Expected then but got ' + lexicon[ifExpr.cursor][1];
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

    parseImplicitPlus(obj):
      local object = self.parseObject(obj.cursor);
      {
        type: 'implicit_plus',
        expr: obj,
        object: object,
        cursor:: object.cursor,
      },

    parseAnonymousFunction(index, endTokens, inObject):
      assert lexicon[index][1] == 'function' : 'Expected "function" but got "%s"' % lexicon[index][1];
      local params = self.parseParams(index + 1);
      local expr = self.parseExpr(params.cursor, endTokens, inObject);
      {
        type: 'anonymous_function',
        params: params,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseAssertionExpr(index, endTokens, inObject):
      local assertion = self.parseAssertion(index, [';'], inObject);
      assert lexicon[assertion.cursor][1] == ';' : 'Expected ; but got ' + lexicon[assertion.cursor][1];
      local expr = self.parseExpr(assertion.cursor + 1, endTokens, inObject);
      {
        type: 'assertion_expr',
        assertion: assertion,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseImport(index):
      local token = lexicon[index];
      local possibleValues = ['importstr', 'importbin', 'import'];

      assert std.member(possibleValues, token[1]) : 'Expected %s but got %s' % [possibleValues, token[1]];

      local map = {
        STRING_SINGLE: this.parseString,
        STRING_DOUBLE: this.parseString,
        VERBATIM_STRING_SINGLE: this.parseVerbatimString,
        VERBATIM_STRING_DOUBLE: this.parseVerbatimString,
      };

      assert !std.startsWith(lexicon[index + 1][0], 'STRING_BLOCK') : 'Block string literal not allowed for imports';
      local parsePath = getParseFunction(map, lexicon[index + 1][0]);
      local path = parsePath(index + 1);

      {
        type: token[1] + '_statement',
        path: path.string,
        cursor:: path.cursor,
      },

    parseErrorExpr(index, endTokens, inObject):
      assert lexicon[index][1] == 'error' : 'Expected "error" but got "%s"' % lexicon[index][1];
      local expr = self.parseExpr(index + 1, endTokens, inObject);
      {
        type: 'error_expr',
        expr: expr,
        cursor:: expr.cursor,
      },

    parseExprInSuper(obj, inObject):
      assert inObject : "Can't use super outside of an object";
      assert lexicon[obj.cursor][1] == 'in'
             && lexicon[obj.cursor + 1][1] == 'super'
             : 'Expected "in super" but got "%s"' % lexicon[obj.cursor][1] + ' ' + lexicon[obj.cursor + 2][1];
      {
        type: 'expr_in_super',
        expr: obj,
        cursor:: obj.cursor + 2,
      },

    parseParenthesis(index):
      assert lexicon[index][1] == '(' : 'Expected "(" but got "%s"' % lexicon[index][1];
      local expr = self.parseExpr(index + 1, [')']);
      assert lexicon[expr.cursor][1] == ')' : 'Expected ")" but got "%s"' % lexicon[expr.cursor][1];
      {
        type: 'parenthesis',
        expr: expr,
        cursor:: expr.cursor + 1,
      },

    parseMember(index, endTokens):
      local token = lexicon[index];
      if token[1] == 'local'
      then self.parseObjectLocal(index, endTokens)
      else if token[1] == 'assert'
      then self.parseAssertion(index, endTokens, inObject=true)
      else self.parseField(index, endTokens),

    parseObjectLocal(index, endTokens):
      local token = lexicon[index];
      assert token[1] == 'local' : 'Expected "local" but got "%s"' % token[1];
      local bind = self.parseBind(index + 1, endTokens, inObject=true);
      {
        type: 'object_local',
        bind: bind,
        cursor:: bind.cursor,
      },

    parseBind(index, endTokens, inObject=false):
      local id = self.parseIdentifier(index);

      local isFunction = (lexicon[id.cursor][1] == '(');
      local params = self.parseParams(id.cursor);

      local nextCursor =
        if isFunction
        then params.cursor
        else id.cursor;

      local operator = lexicon[nextCursor][1];
      assert operator == '=' : 'Expected token = but got "%s"' % operator;

      local expr = self.parseExpr(nextCursor + 1, endTokens, inObject);
      {
        type: 'bind',
        id: id,
        expr: expr,
        cursor:: expr.cursor,
      }
      + (if isFunction
         then {
           type: 'bind_function',
           params: params,
         }
         else {}),

    parseAssertion(index, endTokens, inObject=false):
      assert lexicon[index][1] == 'assert' : 'Expected "assert" but got "%s"' % lexicon[index][1];
      local expr = self.parseExpr(index + 1, [':'] + endTokens, inObject);

      local hasReturnExpr = lexicon[expr.cursor][1] == ':';
      local returnExpr = self.parseExpr(expr.cursor + 1, endTokens, inObject);

      local cursor =
        if hasReturnExpr
        then returnExpr.cursor
        else expr.cursor;

      assert std.member(endTokens, lexicon[cursor][1]) : 'Expected %s but got %s' % [std.toString(endTokens), lexicon[cursor][1]];
      {
        type: 'assertion',
        expr: expr,
        [if hasReturnExpr then 'return_expr']: returnExpr,
        cursor:: cursor,
      },

    parseField(index, endTokens):
      local fieldname = self.parseFieldname(index);

      local isFunction = (lexicon[fieldname.cursor][1] == '(');
      local params = self.parseParams(fieldname.cursor);

      local nextCursor =
        if isFunction
        then params.cursor
        else fieldname.cursor;

      local operator = lexicon[nextCursor][1];
      local expectOp = [':', '::', ':::', '+:', '+::', '+:::'];
      assert std.member(expectOp, operator) : 'Expected token %s but got "%s"' % [std.join('","', expectOp), operator];

      local expr = self.parseExpr(nextCursor + 1, endTokens, true);
      {
        type: 'field',
        fieldname: fieldname,
        h: operator,
        expr: expr,
        cursor:: expr.cursor,
      }
      + (if isFunction
         then {
           type: 'field_function',
           params: params,
         }
         else {}),

    parseFieldname(index):
      local token = lexicon[index];
      if token[1] == '['
      then self.parseFieldnameExpr(index)
      else lexMap[token[0]](index),

    parseFieldnameExpr(index):
      local token = lexicon[index];
      assert token[1] == '[' : 'Expected "[" but got "%s"' % token[1];
      local expr = self.parseExpr(index + 1, endTokens=[']']);
      assert lexicon[expr.cursor][1] == ']' : 'Expected "]" but got "%s"' % lexicon[expr.cursor][1];
      {
        type: 'fieldname_expr',
        expr: expr,
        cursor:: expr.cursor + 1,
      },

    parseParams(index):
      local token = lexicon[index];

      assert token[1] == '(' : 'Expected ( but got ' + token[1];

      local params = parseTokens(index + 1, [')'], ',', self.parseParam);

      local last = std.reverse(params)[0];
      local cursor =
        if std.length(params) > 0
        then last.cursor
        else index + 1;

      assert lexicon[cursor][1] == ')' : 'Expected ) but got ' + lexicon[cursor][1];
      {
        type: 'params',
        params: params,
        cursor:: cursor + 1,
      },

    parseParam(index):
      local endTokens = [',', ')'];
      local id = self.parseExpr(index, endTokens + ['=']);
      local hasExpr = lexicon[id.cursor][1] == '=';
      local expr = self.parseExpr(id.cursor + 1, endTokens);
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

    parseForspec(index, endTokens):
      local token = lexicon[index];
      assert token[1] == 'for' : 'Expected "for" but got "%s"' % token[1];

      local id = self.parseIdentifier(index + 1);

      assert lexicon[id.cursor][1] == 'in' : 'Expected "in" but got "%s"' % lexicon[id.cursor][1];

      local expr = self.parseExpr(id.cursor + 1, endTokens);

      {
        type: 'forspec',
        id: id,
        expr: expr,
        cursor:: expr.cursor,
      },

    parseIfspec(index, endTokens):
      local token = lexicon[index];
      assert token[1] == 'if' : 'Expected "if" but got "%s"' % token[1];

      local expr = self.parseExpr(index + 1, endTokens);
      {
        type: 'ifspec',
        expr: expr,
        cursor:: expr.cursor,
      },

    parseCompspec(index, endTokens):
      local compMap = {
        'if': this.parseIfspec,
        'for': this.parseForspec,
      };
      local items =
        parseTokens(
          // Doing funky index juggling because parseTokens moves index past splitToken
          index + 1,
          endTokens,
          ['for', 'if'],
          function(index)
            local token = lexicon[index - 1];
            if std.member(endTokens, token[1])
            then { cursor: index }
            else
              assert std.member(['for', 'if'], token[1]) : 'Expected "for" or "if" but got "%s"' % std.toString(token);
              compMap[token[1]](index - 1, endTokens + ['for', 'if'])
        );
      local last = std.reverse(items)[0];
      {
        type: 'compspec',
        items: items,
        cursor:: last.cursor,
      },
  },
}
