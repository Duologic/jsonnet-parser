[
  '\\u%s%s%s%s' % [c1, c2, c3, c4]
  for c1 in std.stringChars('0123')
  for c2 in std.stringChars('012345679ABCDEFabcdef')
  for c3 in std.stringChars('012345679ABCDEFabcdef')
  for c4 in std.stringChars('012345679ABCDEFabcdef')
]
