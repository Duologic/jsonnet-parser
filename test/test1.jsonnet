local a = 'a', b = 'b';
local textblock = |||
  d
|||;
local file1 = import './test1.jsonnet';
//local file2 = import @'./test1.j''sonnet';
//local file3 = import |||
// d
//|||;
{
  local textblock = |||
    d
  |||,
}
+ {
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
  local localFunc(b=true, c) = { a: 'a' } + { b: if b then 'a' + a, c: if c then 'b' else 'e' },
  nn: localFunc(true, c=false),

  local anonyF = function() {},
  fieldAnnonyF: function() assert true : 'assertExpr'; [],
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
  local a = (false),
  local b = false,
  [a]: a,
  local c = error 'someError',
  local d = false,
  local e = 'j' in super
  for a in ['a']
  if a == 'a'
  for b in ['a']
  if b == 'a'
}
