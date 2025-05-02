local evaluator = import './eval.libsonnet';

local file = importstr './eval_example.libsonnet';
local imports = {
  'jsonnetfile.json': import 'jsonnetfile.json',
  './README.md': importstr './README.md',
};
//(import './eval_example.libsonnet') ==
evaluator.new('eval_example.libsonnet', file, imports).eval()
//std.objectFields(evaluator.new('./std.jsonnet', importstr 'std.jsonnet').eval())
