{
  a: 'b',
  b: 'c',
} + {
  assert 'a' in super : super.a,
  local a = 'a',
  [4 + 'b' + 1]+::: [super[a]],
} + { b: 'c' }
//+ {
//  ['' + i]: i
//  for i in std.range(0, 2)
//}
