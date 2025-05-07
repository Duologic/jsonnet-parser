local id = { params: [{ id: 'x' }], call(args): args.x };
local callAnonymous(fn, callparams) =
  fn.call(
    std.foldr(
      function(i, callargs)
        callargs { [fn.params[i].id]: callparams[i] },
      std.range(0, std.length(callparams) - 1),
      {}
    )
  );

{
  isString: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.isString(args.v),
  },

  isNumber: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.isNumber(args.v),
  },

  isBoolean: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.isBoolean(args.v),
  },

  isObject: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.isObject(args.v),
  },

  isArray: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.isArray(args.v),
  },

  isFunction: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.isFunction(args.v),
  },

  toString: {
    params: [
      { id: 'a' },
    ],
    call(args):
      std.toString(args.a),
  },

  substr: {
    params: [
      { id: 'str' },
      { id: 'from' },
      { id: 'len' },
    ],
    call(args):
      std.substr(args.str, args.from, args.len),
  },

  startsWith: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.startsWith(args.a, args.b),
  },

  endsWith: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.endsWith(args.a, args.b),
  },

  lstripChars: {
    params: [
      { id: 'str' },
      { id: 'chars' },
    ],
    call(args):
      std.lstripChars(args.str, args.chars),
  },

  rstripChars: {
    params: [
      { id: 'str' },
      { id: 'chars' },
    ],
    call(args):
      std.rstripChars(args.str, args.chars),
  },

  stripChars: {
    params: [
      { id: 'str' },
      { id: 'chars' },
    ],
    call(args):
      std.stripChars(args.str, args.chars),
  },

  stringChars: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.stringChars(args.str),
  },

  parseInt: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.parseInt(args.str),
  },

  parseOctal: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.parseOctal(args.str),
  },

  parseHex: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.parseHex(args.str),
  },

  split: {
    params: [
      { id: 'str' },
      { id: 'c' },
    ],
    call(args):
      std.split(args.str, args.c),
  },

  splitLimit: {
    params: [
      { id: 'str' },
      { id: 'c' },
      { id: 'maxsplits' },
    ],
    call(args):
      std.splitLimit(args.str, args.c, args.maxsplits),
  },

  splitLimitR: {
    params: [
      { id: 'str' },
      { id: 'c' },
      { id: 'maxsplits' },
    ],
    call(args):
      std.splitLimitR(args.str, args.c, args.maxsplits),
  },

  _strReplace: {
    params: [
      { id: 'str' },
      { id: 'from' },
      { id: 'to' },
    ],
    call(args):
      std._strReplace(args.str, args.from, args.to),
  },

  asciiUpper: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.asciiUpper(args.str),
  },

  asciiLower: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.asciiLower(args.str),
  },

  range: {
    params: [
      { id: 'from' },
      { id: 'to' },
    ],
    call(args):
      std.range(args.from, args.to),
  },

  repeat: {
    params: [
      { id: 'what' },
      { id: 'count' },
    ],
    call(args):
      std.repeat(args.what, args.count),
  },

  slice: {
    params: [
      { id: 'indexable' },
      { id: 'index' },
      { id: 'end' },
      { id: 'step' },
    ],
    call(args):
      std.slice(args.indexable, args.index, args.end, args.step),
  },

  member: {
    params: [
      { id: 'arr' },
      { id: 'x' },
    ],
    call(args):
      std.member(args.arr, args.x),
  },

  count: {
    params: [
      { id: 'arr' },
      { id: 'x' },
    ],
    call(args):
      std.count(args.arr, args.x),
  },

  mod: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.mod(args.a, args.b),
  },

  deg2rad: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.deg2rad(args.x),
  },

  rad2deg: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.rad2deg(args.x),
  },

  log2: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.log2(args.x),
  },

  log10: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.log10(args.x),
  },

  map: {
    params: [
      { id: 'func' },
      { id: 'arr' },
    ],
    call(args):
      std.map(function(item) callAnonymous(args.func, [item]), args.arr),
  },

  mapWithIndex: {
    params: [
      { id: 'func' },
      { id: 'arr' },
    ],
    call(args):
      std.mapWithIndex(function(i, x) callAnonymous(args.func, [i, x]), args.arr),
  },

  mapWithKey: {
    params: [
      { id: 'func' },
      { id: 'obj' },
    ],
    call(args):
      std.mapWithKey(function(key, value) callAnonymous(args.func, [key, value]), args.obj),
  },

  flatMap: {
    params: [
      { id: 'func' },
      { id: 'arr' },
    ],
    call(args):
      std.flatMap(function(item) callAnonymous(args.func, [item]), args.arr),
  },

  join: {
    params: [
      { id: 'sep' },
      { id: 'arr' },
    ],
    call(args):
      std.join(args.sep, args.arr),
  },

  lines: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.lines(args.arr),
  },

  deepJoin: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.deepJoin(args.arr),
  },

  format: {
    params: [
      { id: 'str' },
      { id: 'vals' },
    ],
    call(args):
      std.format(args.str, args.vals),
  },

  foldr: {
    params: [
      { id: 'func' },
      { id: 'arr' },
      { id: 'init' },
    ],
    call(args):
      std.foldr(function(item, acc) callAnonymous(args.func, [item, acc]), args.arr, args.init),
  },

  foldl: {
    params: [
      { id: 'func' },
      { id: 'arr' },
      { id: 'init' },
    ],
    call(args):
      std.foldl(function(acc, item) callAnonymous(args.func, [acc, item]), args.arr, args.init),
  },

  filterMap: {
    params: [
      { id: 'filter_func' },
      { id: 'map_func' },
      { id: 'arr' },
    ],
    call(args):
      std.filterMap(function(item) callAnonymous(args.filter_func, [item]), function(item) callAnonymous(args.map_func, [item]), args.arr),
  },

  assertEqual: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.assertEqual(args.a, args.b),
  },

  abs: {
    params: [
      { id: 'n' },
    ],
    call(args):
      std.abs(args.n),
  },

  sign: {
    params: [
      { id: 'n' },
    ],
    call(args):
      std.sign(args.n),
  },

  max: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.max(args.a, args.b),
  },

  min: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.min(args.a, args.b),
  },

  clamp: {
    params: [
      { id: 'x' },
      { id: 'minVal' },
      { id: 'maxVal' },
    ],
    call(args):
      std.clamp(args.x, args.minVal, args.maxVal),
  },

  flattenArrays: {
    params: [
      { id: 'arrs' },
    ],
    call(args):
      std.flattenArrays(args.arrs),
  },

  flattenDeepArray: {
    params: [
      { id: 'value' },
    ],
    call(args):
      std.flattenDeepArray(args.value),
  },

  manifestIni: {
    params: [
      { id: 'ini' },
    ],
    call(args):
      std.manifestIni(args.ini),
  },

  manifestToml: {
    params: [
      { id: 'value' },
    ],
    call(args):
      std.manifestToml(args.value),
  },

  manifestTomlEx: {
    params: [
      { id: 'value' },
      { id: 'indent' },
    ],
    call(args):
      std.manifestTomlEx(args.value, args.indent),
  },

  escapeStringJson: {
    params: [
      { id: 'str_' },
    ],
    call(args):
      std.escapeStringJson(args.str_),
  },

  escapeStringPython: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.escapeStringPython(args.str),
  },

  escapeStringBash: {
    params: [
      { id: 'str_' },
    ],
    call(args):
      std.escapeStringBash(args.str_),
  },

  escapeStringDollars: {
    params: [
      { id: 'str_' },
    ],
    call(args):
      std.escapeStringDollars(args.str_),
  },

  escapeStringXML: {
    params: [
      { id: 'str_' },
    ],
    call(args):
      std.escapeStringXML(args.str_),
  },

  manifestJson: {
    params: [
      { id: 'value' },
    ],
    call(args):
      std.manifestJson(args.value),
  },

  manifestJsonMinified: {
    params: [
      { id: 'value' },
    ],
    call(args):
      std.manifestJsonMinified(args.value),
  },

  manifestJsonEx: {
    params: [
      { id: 'value' },
      { id: 'indent' },
      { id: 'newline', default(_): '\n' },
      { id: 'key_val_sep', default(_): ': ' },
    ],
    call(args):
      std.manifestJsonEx(args.value, args.indent, args.newline, args.key_val_sep),
  },

  manifestYamlDoc: {
    params: [
      { id: 'value' },
      { id: 'indent_array_in_object', default(_): false },
      { id: 'quote_keys', default(_): true },
    ],
    call(args):
      std.manifestYamlDoc(args.value, args.indent_array_in_object, args.quote_keys),
  },

  manifestYamlStream: {
    params: [
      { id: 'value' },
      { id: 'indent_array_in_object', default(_): false },
      { id: 'c_document_end', default(_): true },
      { id: 'quote_keys', default(_): true },
    ],
    call(args):
      std.manifestYamlStream(args.value, args.indent_array_in_object, args.c_document_end, args.quote_keys),
  },

  manifestPython: {
    params: [
      { id: 'v' },
    ],
    call(args):
      std.manifestPython(args.v),
  },

  manifestPythonVars: {
    params: [
      { id: 'conf' },
    ],
    call(args):
      std.manifestPythonVars(args.conf),
  },

  manifestXmlJsonml: {
    params: [
      { id: 'value' },
    ],
    call(args):
      std.manifestXmlJsonml(args.value),
  },

  base64: {
    params: [
      { id: 'input' },
    ],
    call(args):
      std.base64(args.input),
  },

  base64DecodeBytes: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.base64DecodeBytes(args.str),
  },

  base64Decode: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.base64Decode(args.str),
  },

  reverse: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.reverse(args.arr),
  },

  sort: {
    params: [
      { id: 'arr' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.sort(args.arr, function(item) callAnonymous(args.keyF, [item])),
  },

  uniq: {
    params: [
      { id: 'arr' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.uniq(args.arr, function(item) callAnonymous(args.keyF, [item])),
  },

  set: {
    params: [
      { id: 'arr' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.set(args.arr, function(item) callAnonymous(args.keyF, [item])),
  },

  setMember: {
    params: [
      { id: 'x' },
      { id: 'arr' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.setMember(args.x, args.arr, function(item) callAnonymous(args.keyF, [item])),
  },

  setUnion: {
    params: [
      { id: 'a' },
      { id: 'b' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.setUnion(args.a, args.b, function(item) callAnonymous(args.keyF, [item])),
  },

  setInter: {
    params: [
      { id: 'a' },
      { id: 'b' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.setInter(args.a, args.b, function(item) callAnonymous(args.keyF, [item])),
  },

  setDiff: {
    params: [
      { id: 'a' },
      { id: 'b' },
      { id: 'keyF', default(_): id },
    ],
    call(args):
      std.setDiff(args.a, args.b, function(item) callAnonymous(args.keyF, [item])),
  },

  mergePatch: {
    params: [
      { id: 'target' },
      { id: 'patch' },
    ],
    call(args):
      std.mergePatch(args.target, args.patch),
  },

  get: {
    params: [
      { id: 'o' },
      { id: 'f' },
      { id: 'default', default(_): null },
      { id: 'inc_hidden', default(_): true },
    ],
    call(args):
      std.get(args.o, args.f, args.default, args.inc_hidden),
  },

  objectFields: {
    params: [
      { id: 'o' },
    ],
    call(args):
      std.objectFields(args.o),
  },

  objectFieldsAll: {
    params: [
      { id: 'o' },
    ],
    call(args):
      std.objectFieldsAll(args.o),
  },

  objectHas: {
    params: [
      { id: 'o' },
      { id: 'f' },
    ],
    call(args):
      std.objectHas(args.o, args.f),
  },

  objectHasAll: {
    params: [
      { id: 'o' },
      { id: 'f' },
    ],
    call(args):
      std.objectHasAll(args.o, args.f),
  },

  objectValues: {
    params: [
      { id: 'o' },
    ],
    call(args):
      std.objectValues(args.o),
  },

  objectValuesAll: {
    params: [
      { id: 'o' },
    ],
    call(args):
      std.objectValuesAll(args.o),
  },

  objectKeysValues: {
    params: [
      { id: 'o' },
    ],
    call(args):
      std.objectKeysValues(args.o),
  },

  objectKeysValuesAll: {
    params: [
      { id: 'o' },
    ],
    call(args):
      std.objectKeysValuesAll(args.o),
  },

  equals: {
    params: [
      { id: 'a' },
      { id: 'b' },
    ],
    call(args):
      std.equals(args.a, args.b),
  },

  resolvePath: {
    params: [
      { id: 'f' },
      { id: 'r' },
    ],
    call(args):
      std.resolvePath(args.f, args.r),
  },

  prune: {
    params: [
      { id: 'a' },
    ],
    call(args):
      std.prune(args.a),
  },

  findSubstr: {
    params: [
      { id: 'pat' },
      { id: 'str' },
    ],
    call(args):
      std.findSubstr(args.pat, args.str),
  },

  find: {
    params: [
      { id: 'value' },
      { id: 'arr' },
    ],
    call(args):
      std.find(args.value, args.arr),
  },

  all: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.all(args.arr),
  },

  any: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.any(args.arr),
  },

  __compare: {
    params: [
      { id: 'v1' },
      { id: 'v2' },
    ],
    call(args):
      std.__compare(args.v1, args.v2),
  },

  __compare_array: {
    params: [
      { id: 'arr1' },
      { id: 'arr2' },
    ],
    call(args):
      std.__compare_array(args.arr1, args.arr2),
  },

  __array_less: {
    params: [
      { id: 'arr1' },
      { id: 'arr2' },
    ],
    call(args):
      std.__array_less(args.arr1, args.arr2),
  },

  __array_greater: {
    params: [
      { id: 'arr1' },
      { id: 'arr2' },
    ],
    call(args):
      std.__array_greater(args.arr1, args.arr2),
  },

  __array_less_or_equal: {
    params: [
      { id: 'arr1' },
      { id: 'arr2' },
    ],
    call(args):
      std.__array_less_or_equal(args.arr1, args.arr2),
  },

  __array_greater_or_equal: {
    params: [
      { id: 'arr1' },
      { id: 'arr2' },
    ],
    call(args):
      std.__array_greater_or_equal(args.arr1, args.arr2),
  },

  sum: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.sum(args.arr),
  },

  avg: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.avg(args.arr),
  },

  minArray: {
    params: [
      { id: 'arr' },
      { id: 'keyF', default(_): id },
      { id: 'onEmpty', default(_): error 'Expected at least one element in array. Got none' },
    ],
    call(args):
      std.minArray(args.arr, function(item) callAnonymous(args.keyF, [item]), args.onEmpty),
  },

  maxArray: {
    params: [
      { id: 'arr' },
      { id: 'keyF', default(_): id },
      { id: 'onEmpty', default(_): error 'Expected at least one element in array. Got none' },
    ],
    call(args):
      std.maxArray(args.arr, function(item) callAnonymous(args.keyF, [item]), args.onEmpty),
  },

  xor: {
    params: [
      { id: 'x' },
      { id: 'y' },
    ],
    call(args):
      std.xor(args.x, args.y),
  },

  xnor: {
    params: [
      { id: 'x' },
      { id: 'y' },
    ],
    call(args):
      std.xnor(args.x, args.y),
  },

  round: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.round(args.x),
  },

  isEmpty: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.isEmpty(args.str),
  },

  contains: {
    params: [
      { id: 'arr' },
      { id: 'elem' },
    ],
    call(args):
      std.contains(args.arr, args.elem),
  },

  equalsIgnoreCase: {
    params: [
      { id: 'str1' },
      { id: 'str2' },
    ],
    call(args):
      std.equalsIgnoreCase(args.str1, args.str2),
  },

  isEven: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.isEven(args.x),
  },

  isOdd: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.isOdd(args.x),
  },

  isInteger: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.isInteger(args.x),
  },

  isDecimal: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.isDecimal(args.x),
  },

  removeAt: {
    params: [
      { id: 'arr' },
      { id: 'at' },
    ],
    call(args):
      std.removeAt(args.arr, args.at),
  },

  remove: {
    params: [
      { id: 'arr' },
      { id: 'elem' },
    ],
    call(args):
      std.remove(args.arr, args.elem),
  },

  objectRemoveKey: {
    params: [
      { id: 'obj' },
      { id: 'key' },
    ],
    call(args):
      std.objectRemoveKey(args.obj, args.key),
  },

  sha1: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.sha1(args.str),
  },

  sha256: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.sha256(args.str),
  },

  sha512: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.sha512(args.str),
  },

  sha3: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.sha3(args.str),
  },

  trim: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.trim(args.str),
  },

  acos: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.acos(args.x),
  },

  asin: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.asin(args.x),
  },

  atan: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.atan(args.x),
  },

  atan2: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.atan2(args.x),
  },

  ceil: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.ceil(args.x),
  },

  char: {
    params: [
      { id: 'n' },
    ],
    call(args):
      std.char(args.n),
  },

  codepoint: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.codepoint(args.str),
  },

  cos: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.cos(args.x),
  },

  decodeUTF8: {
    params: [
      { id: 'arr' },
    ],
    call(args):
      std.decodeUTF8(args.arr),
  },

  encodeUTF8: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.encodeUTF8(args.str),
  },

  exp: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.exp(args.x),
  },

  exponent: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.exponent(args.x),
  },

  extVar: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.extVar(args.x),
  },

  filter: {
    params: [
      { id: 'func' },
      { id: 'arr' },
    ],
    call(args):
      std.filter(function(item) callAnonymous(args.func, [item]), args.arr),
  },

  floor: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.floor(args.x),
  },

  id: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.id(args.x),
  },

  length: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.length(args.x),
  },

  log: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.log(args.x),
  },

  makeArray: {
    params: [
      { id: 'sz' },
      { id: 'func' },
    ],
    call(args):
      std.makeArray(args.sz, function(item) callAnonymous(args.func, [item])),
  },

  mantissa: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.mantissa(args.x),
  },

  md5: {
    params: [
      { id: 's' },
    ],
    call(args):
      std.md5(args.s),
  },

  modulo: {
    params: [
      { id: 'x' },
      { id: 'y' },
    ],
    call(args):
      std.modulo(args.x, args.y),
  },

  native: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.native(args.x),
  },

  objectFieldsEx: {
    params: [
      { id: 'obj' },
      { id: 'hidden' },
    ],
    call(args):
      std.objectFieldsEx(args.obj, args.hidden),
  },

  objectHasEx: {
    params: [
      { id: 'obj' },
      { id: 'fname' },
      { id: 'hidden' },
    ],
    call(args):
      std.objectHasEx(args.obj, args.fname, args.hidden),
  },

  parseJson: {
    params: [
      { id: 'str' },
    ],
    call(args):
      std.parseJson(args.str),
  },

  parseYaml: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.parseYaml(args.x),
  },

  pow: {
    params: [
      { id: 'x' },
      { id: 'n' },
    ],
    call(args):
      std.pow(args.x, args.n),
  },

  primitiveEquals: {
    params: [
      { id: 'x' },
      { id: 'y' },
    ],
    call(args):
      std.primitiveEquals(args.x, args.y),
  },

  sin: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.sin(args.x),
  },

  sqrt: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.sqrt(args.x),
  },

  strReplace: {
    params: [
      { id: 'str' },
      { id: 'from' },
      { id: 'to' },
    ],
    call(args):
      std.strReplace(args.str, args.from, args.to),
  },

  tan: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.tan(args.x),
  },

  thisFile: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.thisFile(args.x),
  },

  trace: {
    params: [
      { id: 'str' },
      { id: 'rest' },
    ],
    call(args):
      std.trace(args.str, args.rest),
  },

  type: {
    params: [
      { id: 'x' },
    ],
    call(args):
      std.type(args.x),
  },

}
