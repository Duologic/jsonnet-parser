local util = import './util.libsonnet';
local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

{
  local keywords = [
    'assert',
    'error',

    'if',
    'then',
    'else',
    'for',
    //'in', // binaryop
    'super',

    'function',
    'tailstrict',

    'local',
    'import',
    'importstr',
    'importbin',
  ],

  lexIdentifier(str):
    local value =
      if xtd.ascii.isNumber(str[0])
      then ''
      else
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
    if value == 'in'
    then ['OPERATOR', value]
    else if std.member(keywords, value)
    then ['KEYWORD', value]
    else if value != ''
    then ['IDENTIFIER', value]
    else [],

  lexNumber(str):
    local value =
      if !xtd.ascii.isNumber(str[0])
      then ''
      else
        std.foldl(
          function(acc, c)
            if acc.break
            then acc
            else if xtd.ascii.isNumber(c)
            then acc + { value+: c }
            else if acc.hasDecimalPoint
            then error "Couldn't lex number , junk after decimal point"
            else if c == '.' && !acc.hasDecimalPoint
            then acc + { value+: c, hasDecimalPoint: true }
            else acc + { break: true },
          std.stringChars(str),
          {
            break: false,
            hasDecimalPoint: false,
            value: '',
          }
        ).value;
    if value != ''
    then ['NUMBER', value]
    else [],

  lexString(str):
    if std.startsWith(str, "'")
       || std.startsWith(str, '"')
    then self.lexQuotedString(str)
    else if std.startsWith(str, '@')
    then self.lexVerbatimString(str)
    else if std.startsWith(str, '|||')
    then self.lexTextBlock(str)
    else [],

  lexQuotedString(str, escapeChar='\\'):
    assert std.member(['"', "'"], str[0]) : @'Expected '' or " but got %s' % str[0];

    local startChar = str[0];
    local split = xtd.string.splitEscape(str[1:], startChar, escapeChar);
    local value = split[0];
    local endChar = str[std.length(startChar) + std.length(value)][:std.length(startChar)];

    assert endChar == startChar : 'Unterminated String';

    local tokenName = {
      '"': 'STRING_DOUBLE',
      "'": 'STRING_SINGLE',
    };

    [tokenName[startChar], startChar + value + startChar],

  // FIXME: this doesn't work correctly, issue probably in xtd.string.splitEscape function
  lexVerbatimString(str):
    assert str[0] == '@' : 'Expected "@" but got "%s"' % str[0];

    local q = self.lexQuotedString(str[1:], str[1] + str[1]);

    ['VERBATIM_' + q[0], '@' + q[1]],

  lexTextBlock(str):
    local lines = std.split(str, '\n');

    local marker = '|||';

    assert lines[0] == marker : 'Expected "%s" but got "%s"' % [marker, str[:3]];

    local spacesOnFirstLine = lines[1][:std.length(lines[1]) - std.length(std.lstripChars(lines[1], ' '))];

    assert std.length(spacesOnFirstLine) > 0 : "text block's first line must start with whitespace";

    local stringlines =
      std.foldl(
        function(acc, line)
          if acc.break
          then acc
          else if std.startsWith(line, spacesOnFirstLine)
          then acc + { lines+: [line] }
          else acc + { break: true },
        lines[1:],
        { lines: [], break: false }
      ).lines;

    local string = std.join('\n', stringlines);
    local ending = std.lstripChars(lines[1 + std.length(stringlines)], ' ');

    assert ending[:3] == marker : 'text block not terminated with ||| ---%s' % std.manifestJson(ending);

    ['STRING_BLOCK', std.join('\n', [marker, string, marker])],

  lexSymbol(str):
    local symbols = ['{', '}', '[', ']', ',', '.', '(', ')', ';'];
    if std.member(symbols, str[0])
    then ['SYMBOL', str[0]]
    else [],

  lexOperator(str):
    local ops = ['!', '$', ':', '~', '+', '-', '&', '|', '^', '=', '<', '>', '*', '/', '%'];
    local infunc(s) =
      if s != '' && std.member(ops, s[0])
      then [s[0]] + infunc(s[1:])
      else [];
    local q = std.join('', infunc(str));

    if q != '' && q != '|||'
    then ['OPERATOR', q]
    else [],

  lex(s):
    local str = util.stripLeadingComments(s);
    local lexicons = std.filter(
      function(l) l != [], [
        self.lexString(str),
        self.lexIdentifier(str),
        self.lexNumber(str),
        self.lexSymbol(str),
        self.lexOperator(str),
      ]
    );
    assert std.length(lexicons) == 1 : 'Cannot lex: "%s"' % str;
    assert lexicons[0][1] != '' : 'Cannot lex: "%s"' % str;
    lexicons
    + (
      local remainder = str[std.length(lexicons[0][1]):];
      if std.length(lexicons) > 0 && remainder != ''
      then self.lex(remainder)
      else []
    ),
}
