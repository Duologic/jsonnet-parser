function(params, args)
  local paramIds = std.map(function(x) x.id, params);
  local expected = ', expected (%s)' % std.join(', ', paramIds);
  local validArgs =
    std.map(
      function(arg)
        assert
          !std.objectHas(arg, 'id')
          || std.member(paramIds, arg.id)
          : "Function has no parameter '%s'%s"
            % [arg.id, expected]
          ; arg,
      args
    );
  assert std.length(args) <= std.length(params)
         : 'Too many arguments' + expected;

  local getParamExpr(index, param) =
    local findArg =
      std.filter(
        function(arg)
          std.objectHas(arg, 'id')
          && arg.id == param.id,
        validArgs,
      );

    // named argument (has id)
    if std.length(findArg) == 1
    then param + { expr: findArg[0].expr }

    // positional argument (no id)
    else if index < std.length(args)
            && !std.objectHas(args[index], 'id')
    then param + { expr: args[index].expr }

    // has a default value
    else if std.objectHas(param, 'default')
    then param + { expr: param.default }

    // no value found
    else error "Missing argument: '%s'%s" % [param.id, expected];


  {
    [p.id]: p.expr
    for p in
      std.mapWithIndex(
        getParamExpr,
        params
      )
  }
