// Values
// Any value that can be represented with JSON is a valid value for Jsonnet.

[
  // Strings, which can be added together with +.
  'json' + 'net',

  // Numbers, with support for arithmetics
  '1+1 = ' + (1 + 1),
  '7.0/3.0 = ' + (7.0 / 3.0),

  // Booleans, with boolean operators as you’d expect.
  true && false,
  true || false,
  !true,

  // Objects
  {
    local a = c,
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
    //trythis: self.show(myarg='fasd'),
  },
  { key: 'value' },

  // Arrays, with mixed values
  [],
  ['item1', 42],

  // And null
  null,
]
