local eval = import '../eval.libsonnet';

local imp = |||
  3
|||;

local file = |||
  local imp = import 'imp.libsonnet';
  1 + 2 + imp
|||;

eval.new(
  'file.libsonnet',
  file,
  { imports: { 'imp.libsonnet': imp } }
).eval()
