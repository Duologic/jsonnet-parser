{
  a: 'b',
  b: 'c',
} + {
  assert 'a' in super : super.a,
  local a = 'a',
  [4 + 'b' + 1]+::: [super[a]],
} + { b: 'c' }
+ {
  local a = i,
  local b = i,
  local c = i,
  ['' + i]: i,
  local d = i,
  local f = i
  for i in std.range(0, 2)
}
