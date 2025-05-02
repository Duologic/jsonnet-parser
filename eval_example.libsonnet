// Values
// Any value that can be represented with JSON is a valid value for Jsonnet.

local myfn() = false;

local parentIsHidden = false;

assert std.trace('log', true) : 'message';

[
  myfn(),
  // Strings, which can be added together with +.
  'json' + 'net',

  // Numbers, with support for arithmetics
  '1+1 = ' + (1 + 1),
  '7.0/3.0 = ' + (7.0 / 3.0),

  // Booleans, with boolean operators as you’d expect.
  true && false,
  true || false,
  !true,

  //std.isString(parentIsHidden),
  std.thisFile,

  // Objects
  {
    local a = c,
    local aa() = 9000,
    b: self.a,
    a+: a,
    local c = 'aaa',
    ['null' + 1]: c,
    hidden:: 'a',
    show: self.hidden,
    assert self.b == 'aaa' : 'my message',
    abc(myarg, def='op'):: myarg + def,
    printthis: self.abc('a', def='a'),
    aaaaa: std.trace('a', true),
    ty: aa(),
    lib:: { func(): 'return' },
    inst: self.lib.func(),
  },
  { key: 'value' },

  // Arrays, with mixed values
  [
    { yes: a, no: b }
    for a in std.range(0, 2)
    for b in std.range(0, a)
    if a == 2
  ],
  ['item1', 42],

  // And null
  null,
  'realy',

  [
    { a: a, b: b }
    for a in std.range(0, 2)
    for b in std.range(2, 6)
    if a != 2
  ]
  ==
  std.foldr(
    function(fn, acc)
      fn(acc),
    [
      function(acc)
        std.flatMap(
          function(item)
            std.map(
              function(i)
                item + {
                  b: i,
                },
              std.range(2, 6),
            ),
          acc
        ),
      function(acc)
        std.filter(
          function(i)
            i.a != 2,
          acc
        ),
    ],
    std.map(
      function(i)
        { a: i },
      std.range(0, 2),
    ),
  ),
  (function()
     if false
     then
       'a')(),
  {
    local b = 'b',
    ['a' + a]: c + a + b,
    local c = 5
    for a in std.range(0, 2)
  },

  std.range(0, 5)[0:3:2],

  { a: 3 } + { a: 5, b: super.a } + { c: super['a' + ''], d: 'b' in super },

  import 'jsonnetfile.json',
  importstr './README.md',
  //error 'test',
]
