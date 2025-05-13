local a = import '../../crdsonnet/astsonnet/schema.libsonnet';
local parser = import './parser.libsonnet';

local overrides =
  {
    [k]: [{ id: 'str' }]
    for k in [
      'codepoint',
      'encodeUTF8',
      'parseJson',
    ]
  }
  + {
    modulo: [
      { id: 'x' },
      { id: 'y' },
    ],
    primitiveEquals: [
      { id: 'x' },
      { id: 'y' },
    ],
    pow: [
      { id: 'x' },
      { id: 'n' },
    ],
    objectFieldsEx: [
      { id: 'obj' },
      { id: 'hidden' },
    ],
    trace: [
      { id: 'str' },
      { id: 'rest' },
    ],
    strReplace: [
      { id: 'str' },
      { id: 'from' },
      { id: 'to' },
    ],
    objectHasEx: [
      { id: 'obj' },
      { id: 'fname' },
      { id: 'hidden' },
    ],
    char: [
      { id: 'n' },
    ],
    decodeUTF8: [
      { id: 'arr' },
    ],
    md5: [
      { id: 's' },
    ],
    filter: [
      { id: 'func' },
      { id: 'arr' },
    ],
    makeArray: [
      { id: 'sz' },
      { id: 'func' },
    ],
    mapWithIndex: [
      {
        id: 'func',
        funcArgs: ['i', 'x'],
      },
      { id: 'arr' },
    ],
    mapWithKey: [
      {
        id: 'func',
        funcArgs: ['key', 'value'],
      },
      { id: 'obj' },
    ],
    foldl: [
      {
        id: 'func',
        funcArgs: ['acc', 'item'],
      },
      { id: 'arr' },
      { id: 'init' },
    ],
    foldr: [
      {
        id: 'func',
        funcArgs: ['item', 'acc'],
      },
      { id: 'arr' },
      { id: 'init' },
    ],
  };

local evalTemplate(name, arguments) =
  local params =
    std.map(
      function(param)
        std.join(
          ' ',
          [
            '{',
            'id: "%s",' % param.id,
          ]
          + (
            if 'expr' in param
            then [
              'default: ' +
              (
                if std.get(param.expr, 'id', '') == 'id'
                then 'id'
                else param.expr
              ),
            ]
            else []
          )
          + [
            '}',
          ]
        ),
      arguments
    );
  |||
    %(name)s:
        local params = [
          %(params)s
        ];
        function(callArgs, env, locals, evalExpr=evaluator.evalExpr)
          local args = evaluator.evalArgs(
            params,
            env,
            locals,
            callArgs,
            env,
            locals,
            evalExpr,
          );
          std.%(name)s(%(args)s),
  ||| % {
    name: name,
    params: std.join(',\n', params),
    args: std.join(
      ',\n',
      std.map(
        function(arg)
          if std.member(['func', 'keyF'], arg.id)
             || std.endsWith(arg.id, '_func')
          then
            |||
              function(%(funcArgs)s)
                callAnonymous(args.%(id)s, [%(funcArgs)s], env, locals)
            ||| % {
              id: arg.id,
              funcArgs: std.join(
                ',',
                std.get(arg, 'funcArgs', ['x'])
              ),
            }
          else
            'args.%s' % arg.id,
        arguments,
      )
    ),
  };

local fromStdJsonnet = importstr './std.jsonnet';
local parsedStdJsonnet = parser.new(fromStdJsonnet).parse();
local linesFromStdJsonnet =
  std.filterMap(
    function(member)
      member.type == 'field_function',
    function(member)
      local params = std.map(function(arg) { id: arg.id.id, [if 'expr' in arg then 'expr']: arg.expr }, member.params.params);
      evalTemplate(member.fieldname.id, std.get(overrides, member.fieldname.id, params)),
    parsedStdJsonnet.members
  );

local stdFuncs = std.objectFieldsAll(std);
local stdJsonnetFuncs = std.objectFieldsAll(import './std.jsonnet');
local notInStdJsonnet = std.setDiff(stdFuncs, stdJsonnetFuncs);

local linesFromStd =
  std.map(
    function(name)
      evalTemplate(name, std.get(overrides, name, [{ id: 'x' }])),
    notInStdJsonnet,
  );

std.lines(
  [
    "local getArgs = import './params.libsonnet';",
    'function(evaluator)',
    'local id =',
    std.manifestJson({
      expr: {
        id: 'x',
        type: 'id',
      },
      params: {
        params: [
          {
            id: {
              id: 'x',
              type: 'id',
            },
            type: 'param',
          },
        ],
        type: 'params',
      },
      type: 'anonymous_function',
    }) + ';',
    |||
      local callAnonymous(func, callArgs, env, locals) =
        func(
          std.map(
            function(a)
              { expr: a },
            callArgs
          ),
          env,
          locals,
          function(expr, env, locals) expr,
        );
    |||,
    '{',
  ]
  + linesFromStdJsonnet
  + linesFromStd
  + ['}']
)
