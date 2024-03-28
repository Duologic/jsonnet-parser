local file = importstr './test/object.jsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';
local s = import '../../crdsonnet/astsonnet/schema.libsonnet';

local l = {
  local stripLeadingComments(s) =
    local str = stripWhitespace(s);
    local findIndex(t, s) =
      local f = std.findSubstr(t, s);
      if std.length(f) > 0
      then f[0]
      else std.length(s);
    local stripped =
      if std.startsWith(str, '//')
      then str[findIndex('\n', str):]
      else if std.startsWith(str, '#')
      then str[findIndex('\n', str):]
      else if std.startsWith(str, '/*')
      then str[findIndex('*/', str) + 2:]
      else null;
    if stripped != null
    then stripLeadingComments(stripped)
    else stripWhitespace(s),

  local stripWhitespace(str) =
    std.stripChars(str, [' ', '\t', '\n', '\r']),

  local addRemainder(str) =
    local s = stripLeadingComments(str);
    { [if s != '' then 'remainder']:: s },

  local literals = {
    'null': null,
    'true': true,
    'false': false,
    'self': 'self',
    '$': '$',
  },

  local reservedKeywords = [
    'assert',
    'error',

    'if',
    'then',
    'else',
    'for',
    'in',
    'super',

    'function',
    'tailstrict',

    'local',
    'import',
    'importstr',
    'importbin',

    'null',
    'true',
    'false',

    'self',
    '$',
  ],

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

  local startsWithBinaryOperator(str) =
    std.any([
      std.startsWith(str, op)
      for op in binaryoperators
    ]),

  parse(str):
    local return = parseExpr(str, false);
    local remainder = std.get(return, 'remainder', '');

    if remainder == ''
    then return
    else error 'Unexpected: "%s" while parsing terminal' % remainder,

  local parseExpr(str, in_object=true) =
    local s = stripLeadingComments(str);
    assert s != '' : 'Unexpected end of file';
    local found =
      std.filter(
        function(i) i != {},
        [
          parseIdOrLiteral(s),
          parseString(s),
          parseNumber(s),
          parseObject(s),
          parseArray(s),
          parseSuper(s, in_object),
          parseLocalBind(s),
          parseConditional(s),
          parseUnary(s),
          parseAnonymousFunction(s),
          parseAssertionExpr(s),
          parseImport(s, 'import'),
          parseImport(s, 'importstr'),
          parseImport(s, 'importbin'),
          parseErrorExpr(s),
          parseParenthesis(s),
        ]
      );

    if std.length(found) > 1
    then error 'more than 1 expr matched: %s' % std.manifestJson(found)
    else if std.length(found) == 1
    then parseExprRemainder(found[0], in_object)
    else {},

  local parseExprRemainder(obj, in_object) =
    local found =
      std.filter(
        function(i) i != {},
        [
          parseFieldaccess(obj),
          parseIndexing(obj),
          parseFunctioncall(obj),
          parseBinary(obj),
          parseImplicitPlus(obj),
          parseExprInSuper(obj, in_object),
        ]
      );
    if std.length(found) > 1
    then error 'more than 1 expr matched: %s' % std.manifestJson(found)
    else if std.length(found) == 1
    then parseExprRemainder(found[0], in_object)
    else obj,


  local parseIdOrLiteral(s, strict=false) =
    local str = stripLeadingComments(s);
    local isValidIdChar(c) =
      (xtd.ascii.isLower(c)
       || xtd.ascii.isUpper(c)
       || xtd.ascii.isNumber(c)
       || c == '_');

    local parsed =
      if (xtd.ascii.isLower(str[0])
          || xtd.ascii.isUpper(str[0])
          || str[0] == '_')
      then
        std.foldl(
          function(acc, c)
            if 'remainder' in acc
            then acc + { remainder+: c }
            else if !isValidIdChar(c)
            then acc + { remainder: c }
            else acc + { value+: c },
          std.stringChars(str),
          { value: '' }
        )
      else if str[0] == '$'
      then {
        value: '$',
      } + addRemainder(str[1:])
      else {};

    if !('value' in parsed)
    then {}
    else if std.member(std.objectFields(literals), parsed.value)
    then {
      type: 'literal',
      literal: literals[parsed.value],
    } + addRemainder(std.get(parsed, 'remainder', ''))
    else if std.member(reservedKeywords, parsed.value)
    then
      (if strict
       then {
         type: 'reserved',
         reserved: parsed.value,
       }
       else {})
    else {
      type: 'id',
      id: parsed.value,
    } + addRemainder(std.get(parsed, 'remainder', '')),

  local parseLiteral(str) =
    local parsed = parseIdOrLiteral(str, strict=true);
    if parsed.type == 'literal'
    then parsed
    else error 'Expected literal token but got "%s"' % parsed[parsed.type],

  local parseId(str) =
    local parsed = parseIdOrLiteral(str, strict=true);
    if !('type' in parsed)
    then error 'input was "%s"' % str
    else if str != '' && parsed.type == 'id'
    then parsed
    else if str == ''
    then error 'Expected token IDENTIFIER but got end of file'
    else error 'Expected token IDENTIFIER but got "%s"' % parsed[parsed.type],

  local parseString(str) =
    if std.startsWith(str, "'")
       || std.startsWith(str, '"')
    then parseQuotedString(str)
    else if std.startsWith(str, '|||')
    then parseVerbatimString(str)
    else {},

  local parseQuotedString(str) =
    local isEscaped(str) =
      std.foldl(
        function(acc, c)
          if acc.break
          then acc
          else if c == '\\'
          then acc + { escaped: !acc.escaped }
          else acc + { break: true },
        std.reverse(std.stringChars(str)),
        { escaped: false, break: false }
      ).escaped;
    local parsed =
      std.foldl(
        function(acc, c)
          acc + { c: c }
          + (if acc.break
             then {}
             else if (c == acc.startChar && !isEscaped(acc.value))
             then {
               break: true,
               endChar: c,
             }
             else { value+: c }),
        std.stringChars(str)[1:],
        {
          c: '',
          break: false,
          value: '',
          startChar: str[0],
          endChar: error 'Unterminated String',
        },
      );

    local remainder = str[std.length(parsed.startChar + parsed.value + parsed.endChar):];

    if (std.startsWith(str, "'")
        || std.startsWith(str, '"'))
    then {
      type: 'string',
      string: parsed.value,  //replaceEscapeChars,
    } + addRemainder(remainder)
    else {},

  local parseVerbatimString(str) =
    local lines = std.split(str, '\n');
    if lines[0] == '|||'
    then
      local countwhitespacesonfirstline =
        local spaces = std.length(lines[1]) - std.length(std.lstripChars(lines[1], ' '));
        if spaces > 0
        then spaces
        else error "text block's first line must start with whitespace";

      local spaces =
        std.join(
          '',
          std.map(
            function(i) ' ',
            std.range(1, countwhitespacesonfirstline)
          )
        );
      local stringlines =
        std.foldl(
          function(acc, line)
            acc + (
              if acc.break
              then {}
              else if std.startsWith(line, spaces)
              then { lines+: [line[countwhitespacesonfirstline:]] }
              else { lines+: [line], break: true }
            ),
          lines[1:],
          { break: false }
        ).lines;

      local string =
        if std.startsWith(std.reverse(stringlines)[0], '|||')
        then std.join('\n', stringlines[:std.length(stringlines) - 1])
        else error 'text block not terminated with |||';

      local remainder = std.join('\n', lines[std.length(stringlines) + 1:]);
      {
        type: 'string',
        string: string,
        verbatim: true,
      } + addRemainder(remainder)
    else {},

  local parseNumber(str) =
    local parsed =
      std.foldl(
        function(acc, c)
          if acc.break
          then acc
          else
            acc
            + (if xtd.ascii.isNumber(c)
               then { string+: c }
               else { break: true }),
        std.stringChars(str),
        { string: '', break: false }
      );
    if parsed.string != ''
    then {
      type: 'number',
      number: parsed.string,
    } + addRemainder(str[std.length(parsed.string):])
    else {},

  local parseObject(str) =
    local parseRemainder(remainder) =
      if std.startsWith(remainder, '}')
      then []
      else
        local member = parseMember(remainder);
        local next_remainder = std.get(member, 'remainder', '');
        [member] + (
          if std.startsWith(next_remainder, '}')
             || (std.startsWith(next_remainder, ',')
                 && std.startsWith(stripLeadingComments(next_remainder[1:]), '}'))
          then []
          else if std.startsWith(next_remainder, ',')
          then parseRemainder(stripLeadingComments(member.remainder[1:]))
          else if std.startsWith(std.trace(next_remainder, next_remainder), 'for')
          then []
          else error 'Expected a comma before next field, but got "%s"' % remainder
        );
    local members = parseRemainder(stripLeadingComments(str[1:]));

    local last_member = std.reverse(members)[0];

    local fields = std.filter(function(member) member.type == 'field', members);
    local asserts = std.filter(function(member) member.type == 'assertion', members);
    local field =
      if std.length(asserts) != 0
      then error 'Object comprehension cannot have asserts'
      else if std.length(fields) > 1
      then error 'Object comprehension can only have one field'
      else fields[0];

    local fieldIndex = std.prune(std.mapWithIndex(function(i, m) if m == field then i else null, members))[0];
    local left_object_locals = members[:fieldIndex];
    local right_object_locals = members[fieldIndex + 1:];

    local fieldname =
      if field.fieldname.type == 'fieldname_expr'
      then field.fieldname
      else error 'Object comprehensions can only have [e] fields';

    local forspec =
      if std.length(members) >= 1
         && std.startsWith(std.get(last_member, 'remainder', ''), 'for')
      then parseForspec(std.get(last_member, 'remainder', ''))
      else {};

    local compspec = parseCompspec(std.get(forspec, 'remainder', ''));

    local remainder =
      if std.length(members) == 0
      then str[1:]
      else if compspec != {}
      then std.get(compspec, 'remainder', '')
      else if forspec != {}
      then std.get(forspec, 'remainder', '')
      else std.get(last_member, 'remainder', '');

    local final_remainder =
      if std.startsWith(remainder, '}')
      then remainder[1:]
      else if std.startsWith(remainder, ',')
              && std.startsWith(stripLeadingComments(remainder[1:]), '}')
      then stripLeadingComments(remainder[1:])[1:]
      else error 'Expected "}" but got "%s"' % remainder;

    if std.startsWith(str, '{')
    then
      if forspec != {}
      then {
        type: 'object_forloop',
        forspec: forspec,
        [if compspec != {} then 'compspec']: compspec,
        fieldname_expr: fieldname,
        expr: field.expr,
        left_object_locals: left_object_locals,
        right_object_locals: right_object_locals,
      }
      else {
        type: 'object',
        members: members,
      } + addRemainder(final_remainder)
    else {},

  local parseMember(str) =
    local found =
      std.filter(
        function(i) i != {},
        [
          parseObjectLocal(str),
          parseAssertion(str),
          parseField(str),
        ]
      );
    if std.length(found) > 1
    then error 'more than 1 member matched: %s' % std.manifestJson(found)
    else if std.length(found) == 1
    then found[0]
    else {},

  local parseObjectLocal(str) =
    local bind = parseBind(str[std.length('local'):]);
    if std.startsWith(str, 'local')
    then {
      type: 'object_local',
      bind: bind,
    } + addRemainder(std.get(bind, 'remainder', ''))
    else {},

  local parseField(str) =
    local fieldname = parseFieldname(str);

    local additive = (fieldname.remainder[0] == '+');
    local additive_remainder =
      if additive
      then fieldname.remainder[1:]
      else fieldname.remainder;

    local h =
      if additive_remainder[0:3] == ':::'
      then ':::'
      else if additive_remainder[0:2] == '::'
      then '::'
      else if additive_remainder[0] == ':'
      then ':'
      else error 'Expected token ":", "::" or ":::" but got "%s"' % additive_remainder;

    local hidden_remainder = additive_remainder[std.length(h):];

    local expr = parseExpr(hidden_remainder);
    if fieldname != {}
    then {
      type: 'field',
      fieldname: fieldname,
      [if additive then 'additive']: additive,
      h: h,
      expr: expr,
    } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseFieldname(str) =
    local id = parseIdOrLiteral(str);
    local string = parseString(str);
    local expr = parseExpr(str[1:]);
    local expr_remainder =
      if std.startsWith(std.get(expr, 'remainder', ''), ']')
      then expr.remainder[1:]
      else error 'Expected "]" but got "%s"' % std.get(expr, 'remainder', '');
    if std.startsWith(str, '[')
    then {
      type: 'fieldname_expr',
      expr: expr,
    } + addRemainder(expr_remainder)
    else if id != {} && id.type == 'id'
    then id
    else if string != {}
    then string
    else {},

  local parseArray(str) =
    local parseRemainder(remainder) =
      local expr = parseExpr(remainder);
      local next_remainder = std.get(expr, 'remainder', '');
      [expr] + (
        if std.startsWith(next_remainder, ']')
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(expr.remainder[1:])
        else if std.startsWith(next_remainder, 'for')
        then []
        else error 'Expected a comma before next array element, but got %s' % next_remainder
      );
    local items = parseRemainder(str[1:]);

    local forspec =
      if std.length(items) == 1
         && std.startsWith(std.get(items[0], 'remainder', ''), 'for')
      then parseForspec(std.get(items[0], 'remainder', ''))
      else {};

    local compspec = parseCompspec(std.get(forspec, 'remainder', ''));

    local remainder =
      if compspec != {}
      then std.get(compspec, 'remainder', '')
      else if forspec != {}
      then std.get(forspec, 'remainder', '')
      else std.get(std.reverse(items)[0], 'remainder', '');

    local final_remainder =
      if std.startsWith(remainder, ']')
      then remainder[1:]
      else error 'Expected "]" after for clause';

    if std.startsWith(str, '[')
    then
      (if forspec != {}
       then {
         type: 'forloop',
         forspec: forspec,
         [if compspec != {} then 'compspec']: compspec,
         expr: items[0],
       }
       else {
         type: 'array',
         items: items,
       }) + addRemainder(final_remainder)
    else {},

  local parseForspec(str) =
    local id = parseId(stripWhitespace(str[std.length('for'):]));
    local id_remainder =
      if std.startsWith(std.get(id, 'remainder', ''), 'in')
      then stripWhitespace(id.remainder[std.length('in'):])
      else error 'Expected token in but got "%s"' % std.get(id, 'remainder', '');
    local expr = parseExpr(id_remainder);
    if std.startsWith(str, 'for')
    then {
      type: 'forspec',
      id: id,
      expr: expr,
    } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseIfspec(str) =
    local expr = parseExpr(str[std.length('if'):]);
    if std.startsWith(str, 'if')
    then {
      type: 'ifspec',
      expr: expr,
    } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseCompspec(str) =
    local parseRemainder(remainder) =
      local spec =
        if std.startsWith(remainder, 'if')
        then parseIfspec(remainder)
        else if std.startsWith(remainder, 'for')
        then parseForspec(remainder)
        else {};
      local next_remainder = std.get(spec, 'remainder', '');
      (if spec != {}
       then [spec]
       else [])
      + (
        if std.startsWith(next_remainder, 'if')
           || std.startsWith(next_remainder, 'for')
        then parseRemainder(next_remainder)
        else []
      );
    local items = parseRemainder(str);
    if std.length(items) > 0
    then {
      type: 'compspec',
      items: items,
    } + addRemainder(std.get(std.reverse(items)[0], 'remainder', ''))
    else {},

  local parseFieldaccess(obj) =
    local remainder = std.get(obj, 'remainder', '');
    local id = parseId(remainder[1:]);
    if std.startsWith(remainder, '.')
    then {
      type: 'fieldaccess',
      exprs: [obj],
      id: id,
    } + addRemainder(std.get(id, 'remainder', ''))
    else {},

  local parseIndexing(obj) =
    local remainder = std.get(obj, 'remainder', '');
    local expr1 = parseExpr(remainder[1:]);
    local expr2 =
      if std.startsWith(std.get(expr1, 'remainder', ''), ':')
      then parseExpr(expr1.remainder[1:])
      else {};
    local expr3 =
      if std.startsWith(std.get(expr2, 'remainder', ''), ':')
      then parseExpr(expr2.remainder[1:])
      else {};

    local exprs =
      local arr =
        std.filter(
          function(i) i != {},
          [expr1, expr2, expr3],
        );
      if std.length(arr) > 0
      then arr
      else error 'indexing requires an expression';

    local final_remainder =
      local r = std.get(std.reverse(exprs)[0], 'remainder', '');
      if std.startsWith(r, ']')
      then r
      else error 'Expected token "]"';

    if std.startsWith(remainder, '[')
       && std.startsWith(final_remainder, ']')
    then {
      type: 'indexing',
      expr: obj,
      exprs: exprs,
    } + addRemainder(final_remainder[1:])
    else {},

  local parseSuper(str, in_object) =
    if std.startsWith(str, 'super')
    then
      if std.startsWith(str, 'super.')
      then parseFieldaccessSuper(str, in_object)
      else if std.startsWith(str, 'super[')
      then parseIndexingSuper(str, in_object)
      else error 'Expected . or [ after super'
    else {},

  local parseFieldaccessSuper(str, in_object) =
    local id =
      if in_object
      then parseId(str[std.length('super.'):])
      else error "Can't use super outside of an object";
    if std.startsWith(str, 'super.')
    then {
      type: 'fieldaccess_super',
      id: id,
    } + addRemainder(std.get(id, 'remainder', ''))
    else {},

  local parseIndexingSuper(str, in_object) =
    local expr =
      if in_object
      then parseExpr(str[std.length('super['):])
      else error "Can't use super outside of an object";
    local r = std.get(expr, 'remainder', '');
    local remainder =
      if std.startsWith(r, ']')
      then r[1:]
      else error 'Expected "[" but got "%s"' % r;
    if std.startsWith(str, 'super[')
    then {
      type: 'indexing_super',
      expr: expr,
    } + addRemainder(remainder)
    else {},

  local parseFunctioncall(obj) =
    local parseRemainder(remainder) =
      local arg = parseArg(remainder);
      local next_remainder = std.get(arg, 'remainder', '');
      [arg] + (
        if std.startsWith(next_remainder, ')')
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(next_remainder[1:])
        else error 'Expected a comma before next function argument, but got %s' % next_remainder
      );
    local args = parseRemainder(obj.remainder[1:]);

    local validargs =
      std.foldl(
        function(acc, arg)
          acc
          + (if std.length(acc) > 0
                && 'id' in std.reverse(acc)[0]
                && !('id' in arg)
             then error 'Positional argument after a named argument is not allowed'
             else [arg]),
        args,
        []
      );

    local r =
      if std.length(args) == 0
      then obj.remainder
      else std.get(std.reverse(args)[0], 'remainder', '');

    local final_remainder =
      if std.startsWith(r, ')')
      then r[1:]
      else error 'Expected ")" but got "%s"' % r;

    if std.startsWith(std.get(obj, 'remainder', ''), '(')
    then {
      type: 'functioncall',
      expr: obj,
      args: validargs,
    } + addRemainder(final_remainder)
    else {},

  local parseArg(str) =
    local id = parseExpr(str);
    local idremainder = std.get(id, 'remainder', '');
    local expr =
      if id.type == 'id' && std.startsWith(std.get(id, 'remainder', ''), '=')
      then parseExpr(idremainder[1:])
      else {};
    local remainder =
      if expr != {}
      then std.get(expr, 'remainder', '')
      else idremainder;
    { type: 'arg' }
    + addRemainder(remainder)
    + (if expr != {}
       then {
         id: id,
         expr: expr,
       }
       else { expr: id }),

  local parseBind(str) =
    local id = parseId(str);
    local remainder = id.remainder;
    local expr =
      if std.startsWith(remainder, '=')
      then parseExpr(remainder[1:])
      else if std.startsWith(remainder, '(')
      then error 'bind_function not implemented'
      else error 'could not parse bind';
    if 'remainder' in id
    then {
      type: 'bind',
      id: id,
      expr: expr,
    } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseLocalBind(str) =
    local parseRemainder(remainder) =
      local bind = parseBind(remainder);
      local next_remainder = std.get(bind, 'remainder', '');
      [bind] + (
        if std.startsWith(next_remainder, ';')
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(stripWhitespace(next_remainder[1:]))
        else error 'Expected "," or ";" but got %s' % next_remainder
      );
    local binds = parseRemainder(stripLeadingComments(str[std.length('local'):]));
    local binds_remainder = std.get(std.reverse(binds)[0], 'remainder', '')[1:];

    local expr = parseExpr(binds_remainder);
    local remainder = std.get(expr, 'remainder', '');

    if std.startsWith(str, 'local')
    then {
      type: 'local_bind',
      bind: binds[0],
      expr: expr,
      [if std.length(binds) > 1 then 'additional_binds']: binds[1:],
    } + addRemainder(remainder)
    else {},

  local parseConditional(str) =
    local if_expr =
      if std.startsWith(str, 'if')
      then parseExpr(str[std.length('if '):])
      else {};

    local then_expr =
      if std.startsWith(std.get(if_expr, 'remainder', ''), 'then')
      then parseExpr(if_expr.remainder[std.length('then'):])
      else error 'Expected "then"';

    local else_expr =
      if std.startsWith(std.get(then_expr, 'remainder', ''), 'else')
      then parseExpr(then_expr.remainder[std.length('else'):])
      else {};

    local remainder =
      if else_expr != {}
      then std.get(else_expr, 'remainder', '')
      else std.get(then_expr, 'remainder', '');

    if std.startsWith(str, 'if')
    then {
      type: 'conditional',
      if_expr: if_expr,
      then_expr: then_expr,
      [if else_expr != {} then 'else_expr']: else_expr,
    } + addRemainder(remainder)
    else {},

  local parseBinary(expr) =
    local left_expr = expr;
    local remainder = std.get(left_expr, 'remainder', '');
    local right_expr = parseExpr(remainder[1:]);
    if remainder != ''
       && startsWithBinaryOperator(remainder[0])
       && right_expr != {}
    then {
      type: 'binary',
      binaryop: '+',
      left_expr: left_expr,
      right_expr: right_expr,
    } + addRemainder(std.get(right_expr, 'remainder', ''))
    else {},

  local parseUnary(str) =
    local expr = parseExpr(str[1:]);
    if std.member(['-', '+', '!', '~'], str[0])
    then {
      type: 'unary',
      unaryop: str[0],
      expr: expr,
    } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseImplicitPlus(obj) =
    local remainder = std.get(obj, 'remainder', '');
    local object = parseObject(remainder);
    if object != {}
    then {
      type: 'implicit_plus',
      expr: obj,
      object: object,
    } + addRemainder(std.get(object, 'remainder', ''))
    else {},

  local parseAnonymousFunction(str) =
    local params = parseParams(str[std.length('function('):]);
    local params_remainder = std.get(params, 'remainder', '');
    local expr =
      if std.startsWith(params_remainder, ')')
      then parseExpr(params_remainder[1:])
      else error 'Expected ")" but got "%s"' % params_remainder;
    local remainder = std.get(expr, 'remainder', '');

    if std.startsWith(str, 'function(')
    then {
      type: 'anonymous_function',
      params: params,
      expr: expr,
    } + addRemainder(remainder)
    else {},

  local parseParams(str) =
    local parseRemainder(remainder) =
      local param = parseParam(remainder);
      local next_remainder = std.get(param, 'remainder', '');
      [param] + (
        if std.startsWith(next_remainder, ')')
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(next_remainder[1:])
        else error 'Expected a comma before next function parameter, but got %s' % next_remainder
      );
    local params = parseRemainder(str);

    local remainder =
      if std.length(params) == 0
      then str
      else std.get(std.reverse(params)[0], 'remainder', '');

    if std.length(params) > 0
    then {
      type: 'params',
      params: params,
    } + addRemainder(remainder)
    else {},

  local parseParam(str) =
    local id = parseExpr(str);
    local id_remainder = std.get(id, 'remainder', '');
    local expr =
      if id.type == 'id' && std.startsWith(std.get(id, 'remainder', ''), '=')
      then parseExpr(id_remainder[1:])
      else {};
    local remainder =
      if expr != {}
      then std.get(expr, 'remainder', '')
      else id_remainder;
    {
      type: 'param',
      id: id,
      [if expr != {} then 'expr']: expr,
    } + addRemainder(remainder),

  local parseAssertionExpr(str) =
    local assertion = parseAssertion(str);
    local remainder = std.get(assertion, 'remainder', '');
    local expr =
      if std.startsWith(remainder, ';')
      then parseExpr(remainder[1:])
      else {};  //error 'assertion: Expected token ";" but got "%s"' % std.toString(str);
    if assertion != {}
       && expr != {}
    then {
      type: 'assertion_expr',
      assertion: assertion,
      expr: expr,
    } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseAssertion(str) =
    local expr = parseExpr(str[std.length('assert'):]);
    local expr_remainder = std.get(expr, 'remainder', '');
    local return_expr =
      if std.startsWith(expr_remainder, ':')
      then parseExpr(expr_remainder[1:])
      else {};
    local remainder =
      if return_expr != {}
      then std.get(return_expr, 'remainder', '')
      else std.get(expr, 'remainder', '');
    if std.startsWith(str, 'assert')
    then {
      type: 'assertion',
      expr: expr,
      [if return_expr != {} then 'return_expr']: return_expr,
    } + addRemainder(remainder)
    else {},

  local parseImport(str, type) =
    local remainder = stripWhitespace(str[std.length(type):]);
    local parsed = parseExpr(remainder);
    local path =
      if parsed.type == 'string'
      then parsed
      else error 'Computed imports are not allowed';
    if std.startsWith(str, type)
       && path != {}
    then {
      type: type + '_statement',
      path: path.string,
    } + addRemainder(std.get(path, 'remainder', ''))
    else {},

  local parseErrorExpr(str) =
    local expr = parseExpr(str[std.length('error'):]);
    if std.startsWith(str, 'error')
    then
      if expr == {}
      then error 'Unexpected: "%s"' % stripLeadingComments(str[std.length('error'):])
      else {
        type: 'error_expr',
        expr: expr,
      } + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseExprInSuper(obj, in_object) =
    local expr =
      if in_object
      then obj
      else error "Can't use super outside of an object";
    local remainder = std.get(obj, 'remainder', '');
    if std.startsWith(remainder, 'in super')
    then {
      type: 'expr_in_super',
      expr: expr,
    } + addRemainder(remainder[std.length('in super'):])
    else {},

  local parseParenthesis(str) =
    local expr = parseExpr(str[1:]);
    local remainder = std.get(expr, 'remainder', '');
    if std.startsWith(str, '(')
       && std.startsWith(remainder, ')')
    then {
      type: 'parenthesis',
      expr: expr,
    } + addRemainder(remainder[1:])
    else {},
};

local parsed = l.parse(file);
'/*\nOutput:\n\n'
+ s.objectToString(parsed)
+ '\n\n*/'
+ '\n'
+ '\n'
+ std.manifestJson(parsed)
