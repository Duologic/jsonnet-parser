local a = 'a', b = 'b';
{
  id_fieldname: 'stringValue',
  local objlocal = "'double quote",
  'string&fieldname': [
    'a' + b
    for b in ['a', 'b', 'c']
  ],
  ['expr' + '_fieldname']: null,
  assert true,
  assert local b = 'b'; true : 'withReturn',
  someFunction(a='a'):: a,
  local localFunc(b=true, c) = { b: if b then 'a' + a, c: if c then 'b' else 'e' },
  nn: localFunc(true, c=false),
}
+ {
  c:
    local c = 'c';
    self.id_fieldname,
  d: self['string&fieldname'],
  e: self.d[2:],
}
+ {
  f: super['string&fieldname'],
  g: super.id_fieldname,
  h: super.d[:2],
  i: self.someFunction('a'),
  j: self.someFunction(a='a'),
}
+ {
  local a = false,
  local b = false,
  [a]: a,
  local c = false,
  local d = false,
  local e = false
  for a in ['a']
  if a == 'a'
  for b in ['a']
  if b == 'a'
}
