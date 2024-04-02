local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  keywords: [
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

  literals: {
    'null': null,
    'true': true,
    'false': false,
    'self': 'self',
    '$': '$',
  },

  symbols: [
    '{',
    '}',
    '[',
    ']',
    ',',
    '.',
    '(',
    ')',
    ';',
  ],

  unaryoperators:
    [
      '-',
      '+',
      '!',
      '~',
    ],

  binaryoperators: [
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

  stripWhitespace(str):
    std.stripChars(str, [' ', '\t', '\n', '\r']),

  stripLeadingComments(s):
    local str = self.stripWhitespace(s);
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
    then self.stripLeadingComments(stripped)
    else str,

  expectedError(expected, str):
    error 'Expected %s, but got "%s"' % [expected, str[:30]],

  startsWithMember(arr, str):
    std.filter(
      function(i) std.startsWith(str, i),
      arr
    ),

  isValidIdChar(c):
    (xtd.ascii.isLower(c)
     || xtd.ascii.isUpper(c)
     || xtd.ascii.isNumber(c)
     || c == '_'),

  isKeyword(str):
    local s = self.startsWithMember(self.keywords, str);
    if std.length(s) == 0
       || self.isValidIdChar(str[std.length(s[0]):][0])
    then false
    else true,

  isLiteral(str):
    local s = self.startsWithMember(std.objectFields(self.literals), str);
    if std.length(s) == 0
       || self.isValidIdChar(str[std.length(s[0]):][0])
    then false
    else true,

  isSymbol(str):
    local s = self.startsWithMember(self.symbols, str);
    if std.length(s) == 0
    then false
    else true,

  isUnaryop(str):
    local s = self.startsWithMember(self.unaryoperators, str);
    if std.length(s) == 0
    then false
    else true,

  isBinaryop(str):
    local s = self.startsWithMember(self.binaryoperators, str);
    if std.length(s) == 0
    then false
    else true,

  lexOperator(str):
    local ops = ['!', '$', ':', '~', '+', '-', '&', '|', '^', '=', '<', '>', '*', '/', '%'];
    local infunc(str) =
      if std.member(ops, str[0])
      then [str[0]] + infunc(str)
      else [];
    std.join('', infunc(ops)),

  parseBlock(inputString, endTokens, splitToken, parseF):
    local infunc(input) =
      local str = self.stripLeadingComments(input);
      if std.length(self.startsWithMember(endTokens, str)) > 0
      then []
      else
        local item = parseF(str);
        [item]
        + (
          local remainder = std.get(item, 'remainder', '');
          if std.length(self.startsWithMember(endTokens, remainder)) > 0
          then []
          else if std.startsWith(remainder, splitToken)
          then infunc(remainder[std.length(splitToken):])
          else self.expectedError('a comma before next item %s' % std.manifestJson(item), remainder)
        );

    infunc(inputString),
}
