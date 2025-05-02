local parser = import './parser.libsonnet';

local evalTemplate(name, arguments) =
  local params = std.map(function(param) { id: param }, arguments);
  |||
    %(name)s: {
        params: %(params)s,
        call(args):
          std.%(name)s(%(args)s)
    },
  ||| % {
    name: name,
    params: std.manifestJson(params),
    args: std.join(',', ['args.%s' % arg for arg in arguments]),
  };

local fromStdJsonnet = importstr './std.jsonnet';
local parsedStdJsonnet = parser.new(fromStdJsonnet).parse();
local linesFromStdJsonnet =
  std.filterMap(
    function(member)
      member.type == 'field_function',
    function(member)
      local params = std.map(function(arg) arg.id.id, member.params.params);
      evalTemplate(member.fieldname.id, params),
    parsedStdJsonnet.members
  );

local stdFuncs = std.objectFieldsAll(std);
local stdJsonnetFuncs = std.objectFieldsAll(fromStdJsonnet);
local notInStdJsonnet = std.setDiff(stdFuncs, stdJsonnetFuncs);

local args(name) =
  std.get(
    {
      primitiveEquals: ['x', 'y'],
      pow: ['x', 'n'],
      objectFieldsEx: ['obj', 'hidden'],
    },
    name,
    ['x']
  );

local linesFromStd =
  std.map(
    function(name)
      evalTemplate(name, args(name)),
    notInStdJsonnet,
  );

std.lines(
  ['{']
  + linesFromStdJsonnet
  + linesFromStd
  + ['}']
)
