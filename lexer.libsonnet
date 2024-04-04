local xtd = import 'github.com/jsonnet-libs/xtd/main.libsonnet';

local isNumber(c) =
  xtd.ascii.isNumber(c);

local isValidIdChar(c) =
  (xtd.ascii.isLower(c)
   || xtd.ascii.isUpper(c)
   || xtd.ascii.isNumber(c)
   || c == '_');

local stripWhitespace(str) =
  std.stripChars(str, [' ', '\t', '\n', '\r']);

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
  else str;

{
  keywords: [
    'assert',
    'error',

    'if',
    'then',
    'else',
    'for',
    'in',  // binaryop, see lexIdentifier
    'super',

    'function',
    'tailstrict',

    'local',
    'import',
    'importstr',
    'importbin',

    // literals, handled by parser
    //'null',
    //'true',
    //'false',
    //'self',
    //'$', // see lexOperator
  ],

  lexIdentifier(str):
    local value =
      if isNumber(str[0])
      then ''
      else
        std.foldl(
          function(acc, c)
            if acc.break
            then acc
            else if isValidIdChar(c)
            then acc + { value+: c }
            else acc + { break: true },
          std.stringChars(str),
          { value: '', break: false }
        ).value;
    if value == 'in'
    then ['OPERATOR', value]
    else if std.member(self.keywords, value)
    then ['KEYWORD', value]
    else if value != ''
    then ['IDENTIFIER', value]
    else [],

  lexNumber(str):
    local value =
      if !isNumber(str[0])
      then ''
      else
        std.foldl(
          function(acc, c)
            if acc.break
            then acc
            else if isNumber(c)
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
    else if std.startsWith(str, '|||\n')
    then self.lexTextBlock(str)
    else [],

  lexQuotedString(str):
    assert std.member(['"', "'"], str[0]) : 'Expected \' or " but got %s' % str[0];

    local startChar = str[0];

    local findLastChar = std.map(function(i) i + 1, std.findSubstr(startChar, str[1:]));

    local isEscaped(index) =
      index > 1
      && str[index - 1] == '\\'
      && !isEscaped(index - 1);

    local lastCharIndices = std.filter(function(e) !isEscaped(e), findLastChar);

    assert std.length(lastCharIndices) > 0 : 'Unterminated String';

    local value = str[1:lastCharIndices[0]];
    local lastChar = str[lastCharIndices[0]];

    local tokenName = {
      '"': 'STRING_DOUBLE',
      "'": 'STRING_SINGLE',
    };

    [tokenName[startChar], startChar + value + lastChar],

  lexVerbatimString(str):
    assert str[0] == '@' : 'Expected "@" but got "%s"' % str[0];

    local startChar = str[1];
    assert std.member(['"', "'"], startChar) : 'Expected \' or " but got %s' % startChar;

    local sub = std.strReplace(str[2:], startChar + startChar, std.char(7));  // replace with BEL character to avoid matching
    local lastCharIndices = std.map(function(i) i + 3, std.findSubstr(startChar, sub));

    assert std.length(lastCharIndices) > 0 : 'Unterminated String';

    local value = str[1:lastCharIndices[0]];
    local lastChar = str[lastCharIndices[0]];

    local tokenName = {
      '"': 'VERBATIM_STRING_DOUBLE',
      "'": 'VERBATIM_STRING_SINGLE',
    };
    [tokenName[startChar], '@' + startChar + value + lastChar],

  lexTextBlock(str):
    local lines = std.split(str, '\n');

    local marker = '|||';

    assert lines[0] == marker : 'Expected "%s" but got "%s"' % [marker, lines[0]];

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
    local endmarkerIndex = std.findSubstr(marker, lines[1 + std.length(stringlines)])[0];
    local endmarker = lines[1 + std.length(stringlines)][:endmarkerIndex + 3];
    local ending = std.lstripChars(endmarker, ' ');

    assert ending == marker : 'text block not terminated with ||| ---%s' % std.manifestJson(endmarkerIndex);

    ['STRING_BLOCK', std.join('\n', [marker, string, endmarker])],

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

    assert !std.member(q, '//') : 'The sequence // is not allowed in an operator.';
    assert !std.member(q, '/*') : 'The sequence /* is not allowed in an operator.';

    local noEndSequence = ['+', '-', '~', '!', '$'];
    assert !(std.length(q) > 1 && std.member(noEndSequence, q[std.length(q) - 1]))
           : 'If the sequence has more than one character, it is not allowed to end in any of +, -, ~, !, $.';

    if q == '$'
    then ['IDENTIFIER', q]
    else if q != ''
            && q != '|||'  // don't assert on this as it is handled by lexTextBlock
    then ['OPERATOR', q]
    else [],

  lex(s, prevEndLineNr=0, prevColumnNr=1, prev=[]):
    local str = stripLeadingComments(s);
    if str == ''
    then []
    else
      local lexicons = std.filter(
        function(l) l != [], [
          self.lexString(str),
          self.lexIdentifier(str),
          self.lexNumber(str),
          self.lexSymbol(str),
          self.lexOperator(str),
        ]
      );
      local value = lexicons[0][1];
      assert std.length(lexicons) == 1 : 'Cannot lex: "%s"' % std.manifestJson(prev);
      assert value != '' : 'Cannot lex: "%s"' % str;

      local countNewlines(s) = std.length(std.findSubstr('\n', s));
      local removedNewlinesCount = countNewlines(s) - countNewlines(str);
      local newlinesInLexicon = countNewlines(value);

      local endLineNr =
        prevEndLineNr
        + removedNewlinesCount
        + countNewlines(str[:std.length(value)]);
      local lineNr = endLineNr - newlinesInLexicon;

      local startColumnNr =
        if lineNr > prevEndLineNr
        then 1
        else prevColumnNr;
      local leadingSpacesCount = std.length(std.lstripChars(s, '\n')) - std.length(std.lstripChars(s, ' \n'));

      local columnNr = startColumnNr + leadingSpacesCount;
      local endColumnNr =
        if newlinesInLexicon == 0
        then columnNr + std.length(value)
        else columnNr;

      [lexicons[0] + [{ line: lineNr, column: columnNr }]]
      + (
        local remainder = str[std.length(lexicons[0][1]):];
        if std.length(lexicons) > 0 && remainder != ''
        then self.lex(remainder, endLineNr, endColumnNr, prev + lexicons)
        else []
      ),
}
