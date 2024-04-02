local file = importstr './test/object.jsonnet';
local s = import '../../crdsonnet/astsonnet/schema.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local util = import './util.libsonnet';

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
    { [if s != '' then 'remainder']: std.trace(s[:50], s) },

  local expectedError(expected, str) =
    error 'Expected %s, but got "%s"' % [expected, str[:30]],

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

  local unaryoperators = ['-', '+', '!', '~'],

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

  local parseBinaryOperator(str) =
    local operators = std.reverse(std.sort(
      [
        op
        for op in binaryoperators
        if std.startsWith(str, op)
      ],
      function(i) std.length(i)
    ));
    if std.length(operators) > 0
    then operators[0]
    else '',

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

    local expr =
      if util.isLiteral(s)
      then parseLiteral(s)
      else if std.startsWith(s, '@')
              || std.startsWith(s, '"')
              || std.startsWith(s, "'")
              || std.startsWith(s, '|||')
      then parseString(s)
      else if xtd.ascii.isNumber(s[0])
      then parseNumber(s)
      else if !util.isKeyword(s)
              && !util.isSymbol(s)
              && !util.isUnaryop(s)
      then parseId(s)
      else if std.startsWith(s, '{')
      then parseObject(s)
      else if std.startsWith(s, '[')
      then parseArray(s)
      else if std.startsWith(s, 'super')
      then parseSuper(s, in_object)
      else if std.startsWith(s, 'local')
      then parseLocalBind(s)
      else if std.startsWith(s, 'if')
      then parseConditional(s)
      else if util.isUnaryop(s)
      then parseUnary(s)
      else if std.startsWith(s, 'function')
      then parseAnonymousFunction(s)
      else if std.startsWith(s, 'assert')
      then parseAssertionExpr(s)
      else if std.startsWith(s, 'import')
      then parseImport(s)
      else if std.startsWith(s, 'error')
      then parseErrorExpr(s)
      else if std.startsWith(s, '(')
      then parseParenthesis(s)
      else error 'no match';

    parseExprRemainder(expr, in_object),

  local parseExprRemainder(obj, in_object) =
    local s = std.get(obj, 'remainder', '');
    local expr =
      if std.startsWith(s, '.')
      then parseFieldaccess(obj)
      else if std.startsWith(s, '[')
      then parseIndexing(obj)
      else if std.startsWith(s, '(')
      then parseFunctioncall(obj)
      else if std.startsWith(s, '{')
      then parseImplicitPlus(obj)
      else if std.startsWith(s, 'in super')
      then parseExprInSuper(obj, in_object)
      else if util.isBinaryop(s)
      then parseBinary(obj)
      else null;

    if expr != null
    then parseExprRemainder(expr, in_object)
    else obj,

  local parseLiteral(str) =
    assert util.isLiteral(str) : 'Expected literal token but got "%s"' % str[:10];
    {
      local s = self.startsWithMember(std.objectFields(self.literals), str),
      type: 'literal',
      literal: util.literals[s[0]],
    } + addRemainder(str[std.length(s[0]):]),

  local parseId(str) =
    assert !util.isKeyword(str)
           && !util.isSymbol(str)
           && !util.isUnaryop(str)
           && !xtd.ascii.isNumber(str[0])
           : 'Expected token IDENTIFIER but got "%s"' % str[:10];

    local id =
      std.foldl(
        function(acc, c)
          if acc.break
          then acc
          else if util.isValidIdChar(c)
          then acc + { value+: c }
          else acc + { break: true },
        std.stringChars(str),
        { value: '', break: false }
      ).value;

    {
      type: std.trace(id, 'id'),
      id: id,
      isKeyword: util.startsWithMember(util.keywords, str),
      keywords: str,
    } + addRemainder(str[std.length(id):]),

  local parseString(str) =
    if std.startsWith(str, "'")
       || std.startsWith(str, '"')
    then parseQuotedString(str)
    else if std.startsWith(str, '@')
    then parseVerbatimString(str)
    else if std.startsWith(str, '|||')
    then parseTextBlock(str)
    else {},

  local parseQuotedString(str, escapeChar='\\') =
    assert (std.startsWith(str, "'")
            || std.startsWith(str, '"'))
           : 'Expected \' or " but got %s' % str[0];

    local startChar = str[0];
    local split = xtd.string.splitEscape(str[1:], startChar, escapeChar);
    local value = split[0];
    local remainder = str[std.length(startChar) + std.length(value) + std.length(startChar):];

    {
      type: 'string',
      string: value,
    } + addRemainder(remainder),

  local parseVerbatimString(str) =
    assert str[0] == '@' : 'Expected "@" but got "%s"' % str[0];

    parseQuotedString(str[1], str[1])
    + { verbatim: true },

  local parseTextBlock(str) =
    local lines = std.split(str, '\n');
    if lines[0] == '|||'
    then
      // FIXME: this assumes that the textblock starts at column 0, this is rarely the case, probably needs to be solved while lexing
      local spacesOnFirstLine = lines[1][std.length(lines[1]) - std.length(std.lstripChars(lines[1], ' ')):];

      assert std.length(spacesOnFirstLine) > 0 : "text block's first line must start with whitespace";

      local stringlines =
        std.foldl(
          function(acc, line)
            acc + (
              if acc.break
              then {}
              else if std.startsWith(line, spacesOnFirstLine)
              then { lines+: [line[std.length(spacesOnFirstLine):]] }
              else { lines+: [line], break: true }
            ),
          lines[1:],
          { break: false }
        ).lines;

      assert std.startsWith(std.reverse(stringlines)[0], '|||')
             : 'text block not terminated with |||';

      local string = std.join('\n', stringlines[:std.length(stringlines) - 1]);

      local remainder = std.join('\n', lines[std.length(stringlines) + 1:]);
      {
        type: 'string',
        string: string,
        textblock: true,
      } + addRemainder(remainder)
    else {},

  local parseNumber(str) =
    local parsed =
      std.foldl(
        function(acc, c)
          if acc.break
          then acc
          else if xtd.ascii.isNumber(c)
          then acc + { string+: c }
          else if acc.hasDecimalPoint
          then error "Couldn't lex number , junk after decimal point"
          else if c == '.' && !acc.hasDecimalPoint
          then acc + { string+: c, hasDecimalPoint: true }
          else acc + { break: true },
        std.stringChars(str),
        {
          break: false,
          hasDecimalPoint: false,
          string: '',
        }
      );
    if parsed.string != ''
    then {
      type: 'number',
      number: parsed.string,
    } + addRemainder(str[std.length(parsed.string):])
    else {},

  local parseObject(str) =
    local s = stripLeadingComments(str[1:]);
    local members = util.parseBlock(s, ['}', 'for'], ',', parseMember);

    local last_member = std.reverse(members)[0];

    local fields = std.filter(function(member) member.type == 'field' || member.type == 'field_function', members);
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

    local forspec =
      if std.length(members) >= 1
         && std.startsWith(std.get(last_member, 'remainder', ''), 'for')
      then parseForspec(std.get(last_member, 'remainder', ''))
      else {};

    local compspec = parseCompspec(std.get(forspec, 'remainder', ''));

    local remainder =
      if std.length(members) == 0
      then s
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
        field: field,
        left_object_locals: left_object_locals,
        right_object_locals: right_object_locals,
      }
      else {
        type: 'object',
        members: members,
      } + addRemainder(final_remainder)
    else {},

  local parseMember(str) =
    if !util.isKeyword(str)
    then parseField(str)
    else if std.startsWith(str, 'local')
    then parseObjectLocal(str)
    else if std.startsWith(str, 'assert')
    then parseAssertion(str)
    else {},

  local parseObjectLocal(str) =
    assert std.startsWith(str, 'local') : 'Expected "local" but got "%s"' % str[:10];
    local bind = parseBind(stripLeadingComments(str[std.length('local'):]));
    {
      type: 'object_local',
      bind: bind,
    } + addRemainder(std.get(bind, 'remainder', '')),

  local parseField(str) =
    assert str != '' : 'Unexpected: end of file while parsing field definition';

    local fieldname = parseFieldname(str);

    local isFunction = (fieldname.remainder[0] == '(');
    local params =
      if isFunction
      then parseParams(fieldname.remainder[1:])
      else {};

    local params_remainder = std.get(params, 'remainder', '');
    local fieldname_remainder =
      if std.startsWith(params_remainder, ')')
      then params_remainder[1:]
      else fieldname.remainder;

    local additive = (fieldname_remainder[0] == '+');
    local additive_remainder =
      if additive
      then fieldname_remainder[1:]
      else fieldname_remainder;

    local op = util.lexOperator(str);
    local expectOp = [':', '::', ':::', '+:', '+::', '+:::'];
    assert std.member(expectOp, op) : 'Expected token %s but got "%s"' % [std.join('","', expectOp), op];

    local additive = op[0] == '+';

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
    then
      (if isFunction
       then {
         type: 'field_function',
         fieldname: fieldname,
         h: h,
         expr: expr,
         params: params,
       }
       else {
         type: 'field',
         fieldname: fieldname,
         [if additive then 'additive']: additive,
         h: h,
         expr: expr,
       }) + addRemainder(std.get(expr, 'remainder', ''))
    else {},

  local parseFieldname(str) =
    local expr = parseExpr(str[1:]);
    local expr_remainder =
      if std.startsWith(std.get(expr, 'remainder', ''), ']')
      then expr.remainder[1:]
      else error 'Expected "]" but got "%s"' % std.get(expr, 'remainder', '');
    if std.startsWith(str, '[')
    then parseFieldnameExpr(str)
    else if std.startsWith(str, '@')
            || std.startsWith(str, '"')
            || std.startsWith(str, "'")
            || std.startsWith(str, '|||')
    then parseString(str)
    else parseId(str),

  local parseFieldnameExpr(str) =
    assert std.startsWith(str, '[') : 'Expected "[" but got "%s"' % str[0];
    local expr = parseExpr(str[1:]);
    local remainder = std.get(expr, 'remainder', '');
    assert std.startsWith(remainder, ']') : 'Expected "]" but got "%s"' % str[0];
    {
      type: 'fieldname_expr',
      expr: expr,
    } + addRemainder(remainder[1:]),

  local parseArray(str) =
    local s = stripLeadingComments(str[1:]);
    local parseRemainder(remainder) =
      local expr = parseExpr(remainder);
      local next_remainder = std.get(expr, 'remainder', '');
      [expr] + (
        if std.startsWith(next_remainder, ']')
           || (std.startsWith(next_remainder, ',')
               && std.startsWith(stripLeadingComments(next_remainder[1:]), ']'))
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(stripLeadingComments(expr.remainder[1:]))
        else if std.startsWith(next_remainder, 'for')
        then []
        else expectedError('a comma before next array element', next_remainder)
      );
    local items =
      if std.startsWith(s, ']')
      then []
      else parseRemainder(s);

    local last_item = std.reverse(items)[0];

    local forspec =
      if std.length(items) == 1
         && std.startsWith(std.get(items[0], 'remainder', ''), 'for')
      then parseForspec(std.get(items[0], 'remainder', ''))
      else {};

    local compspec = parseCompspec(std.get(forspec, 'remainder', ''));

    local remainder =
      if std.length(items) == 0
      then s
      else if compspec != {}
      then std.get(compspec, 'remainder', '')
      else if forspec != {}
      then std.get(forspec, 'remainder', '')
      else std.get(last_item, 'remainder', '');

    local final_remainder =
      if std.startsWith(remainder, ']')
      then remainder[1:]
      else if (std.startsWith(remainder, ',')
               && std.startsWith(stripLeadingComments(remainder[1:]), ']'))
      then stripLeadingComments(remainder[1:])[1:]
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
    local parseIndex(str, nextChar=':') =
      local s = stripWhitespace(str);
      if std.startsWith(s, nextChar)
      then {
        type: 'literal',
        literal: '',
      } + addRemainder(s)
      else parseExpr(str);

    local expr1 = parseIndex(remainder[1:]);
    local expr2 =
      if std.startsWith(std.get(expr1, 'remainder', ''), ':')
      then parseIndex(expr1.remainder[1:])
      else {};
    local expr3 =
      if std.startsWith(std.get(expr2, 'remainder', ''), ':')
      then parseIndex(expr2.remainder[1:], ']')
      else {};

    local exprs =
      local arr =
        std.filter(
          function(i) i != {},
          [expr1, expr2, expr3],
        );
      if std.length(arr) > 0
      then arr
      else error 'indexing requires an expression but got "%s"' % remainder[:30];

    local final_remainder =
      local r = std.get(std.reverse(exprs)[0], 'remainder', '');
      if std.startsWith(r, ']')
      then r[1:]
      else if (std.startsWith(r, ':')
               && std.startsWith(stripLeadingComments(r[1:]), ']'))
      then stripLeadingComments(r[1:])[1:]
      else expectedError('token "]"', r);

    if std.startsWith(remainder, '[')
    then {
      type: 'indexing',
      expr: obj,
      exprs: exprs,
    } + addRemainder(final_remainder)
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
    local s = stripLeadingComments(obj.remainder[1:]);
    local parseRemainder(remainder) =
      local arg = parseArg(remainder);
      local next_remainder = std.get(arg, 'remainder', '');
      [arg] + (
        if std.startsWith(next_remainder, ')')
           || (std.startsWith(next_remainder, ',')
               && std.startsWith(stripLeadingComments(next_remainder[1:]), ')'))
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(next_remainder[1:])
        else expectedError('a comma before next function argument', next_remainder)
      );
    local args =
      if std.startsWith(s, ')')
      then []
      else parseRemainder(s);

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
      else if std.startsWith(r, ',')
              && std.startsWith(stripLeadingComments(r[1:]), ')')
      then stripLeadingComments(r[1:])[1:]
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

    local isFunction = std.startsWith(id.remainder, '(');
    local params =
      if isFunction
      then parseParams(id.remainder[1:])
      else {};

    local params_remainder = std.get(params, 'remainder', '');
    local remainder =
      if std.startsWith(params_remainder, ')')
      then stripLeadingComments(params_remainder[1:])
      else id.remainder;

    local expr =
      if std.startsWith(remainder, '=')
      then parseExpr(remainder[1:])
      else error 'Expected operator = but got "%s"' % std.toString(id);

    (if std.trace(id.id, isFunction)
     then {
       type: 'bind_function',
       id: id,
       expr: expr,
       params: params,
       a: stripLeadingComments(remainder[1:]),
     }
     else {
       type: 'bind',
       id: id,
       expr: expr,
     }) + addRemainder(std.get(expr, 'remainder', '')),

  local parseLocalBind(str) =
    local parseRemainder(remainder) =
      local bind = parseBind(remainder);
      local next_remainder = std.get(bind, 'remainder', '');
      [bind] + (
        if std.startsWith(next_remainder, ';')
        then []
        else if std.startsWith(next_remainder, ',')
        then parseRemainder(stripWhitespace(next_remainder[1:]))
        else expectedError('"," or ";" (%s)' % std.manifestJson(bind), remainder)
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
      then parseExpr(str[std.length('if'):])
      else {};

    local then_expr =
      if std.startsWith(std.get(if_expr, 'remainder', ''), 'then')
      then parseExpr(if_expr.remainder[std.length('then'):])
      else expectedError('then (%s)' % std.manifestJson(if_expr + { str: str[:20] }), std.get(if_expr, 'remainder', ''));

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
    local binaryop = parseBinaryOperator(remainder);
    local right_expr = parseExpr(remainder[std.length(binaryop):]);
    if binaryop != ''
    then {
      type: 'binary',
      binaryop: binaryop,
      left_expr: left_expr,
      right_expr: right_expr,
    } + addRemainder(std.get(right_expr, 'remainder', ''))
    else {},

  local parseUnary(str) =
    local expr = parseExpr(str[1:]);
    if std.member(unaryoperators, str[0])
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
    local params =
      if std.startsWith(str, ')')
      then []
      else parseRemainder(str);

    local remainder =
      if std.length(params) == 0
      then str
      else std.get(std.reverse(params)[0], 'remainder', '');

    {
      type: 'params',
      params: params,
    } + addRemainder(remainder),

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

    if id != {}
    then {
      type: 'param',
      id: id,
      [if expr != {} then 'expr']: expr,
    } + addRemainder(remainder)
    else {},

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

  local parseImport(str) =
    local type =
      std.filter(
        function(t) std.startsWith(str, t),
        ['importstr', 'importbin', 'import']
      );
    local remainder = stripWhitespace(str[std.length(type[0]):]);
    local parsed = parseString(remainder);
    local path =
      if 'type' in parsed && parsed.type == 'string'
      then parsed.string
      else error 'Computed imports are not allowed %s' % std.toString(parsed);
    if std.length(type) > 0
    then {
      type: type[0] + '_statement',
      path: path,
    } + addRemainder(std.get(parsed, 'remainder', ''))
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
    local r = std.get(expr, 'remainder', '');
    local remainder =
      if std.startsWith(r, ')')
      then r[1:]
      else expectedError('parenthesis not closed', r);
    if std.startsWith(str, '(')
    then {
      type: 'parenthesis',
      expr: expr,
    } + addRemainder(remainder)
    else {},
};

local parsed = l.parse(file);
'/*\nOutput:\n\n'
+ s.objectToString(parsed)
+ '\n\n*/'
+ '\n'
+ '\n'
+ std.manifestJson(parsed)
