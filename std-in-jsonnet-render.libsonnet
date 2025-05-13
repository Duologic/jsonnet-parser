local getArgs = import './params.libsonnet';
function(evaluator)
  local id =
    {
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
    };
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

  {
    isString:
      local params = [
        { id: 'v' },
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
        std.isString(args.v),

    isNumber:
      local params = [
        { id: 'v' },
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
        std.isNumber(args.v),

    isBoolean:
      local params = [
        { id: 'v' },
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
        std.isBoolean(args.v),

    isObject:
      local params = [
        { id: 'v' },
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
        std.isObject(args.v),

    isArray:
      local params = [
        { id: 'v' },
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
        std.isArray(args.v),

    isFunction:
      local params = [
        { id: 'v' },
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
        std.isFunction(args.v),

    toString:
      local params = [
        { id: 'a' },
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
        std.toString(args.a),

    substr:
      local params = [
        { id: 'str' },
        { id: 'from' },
        { id: 'len' },
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
        std.substr(args.str,
                   args.from,
                   args.len),

    startsWith:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.startsWith(args.a,
                       args.b),

    endsWith:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.endsWith(args.a,
                     args.b),

    lstripChars:
      local params = [
        { id: 'str' },
        { id: 'chars' },
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
        std.lstripChars(args.str,
                        args.chars),

    rstripChars:
      local params = [
        { id: 'str' },
        { id: 'chars' },
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
        std.rstripChars(args.str,
                        args.chars),

    stripChars:
      local params = [
        { id: 'str' },
        { id: 'chars' },
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
        std.stripChars(args.str,
                       args.chars),

    stringChars:
      local params = [
        { id: 'str' },
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
        std.stringChars(args.str),

    parseInt:
      local params = [
        { id: 'str' },
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
        std.parseInt(args.str),

    parseOctal:
      local params = [
        { id: 'str' },
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
        std.parseOctal(args.str),

    parseHex:
      local params = [
        { id: 'str' },
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
        std.parseHex(args.str),

    split:
      local params = [
        { id: 'str' },
        { id: 'c' },
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
        std.split(args.str,
                  args.c),

    splitLimit:
      local params = [
        { id: 'str' },
        { id: 'c' },
        { id: 'maxsplits' },
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
        std.splitLimit(args.str,
                       args.c,
                       args.maxsplits),

    splitLimitR:
      local params = [
        { id: 'str' },
        { id: 'c' },
        { id: 'maxsplits' },
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
        std.splitLimitR(args.str,
                        args.c,
                        args.maxsplits),

    _strReplace:
      local params = [
        { id: 'str' },
        { id: 'from' },
        { id: 'to' },
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
        std._strReplace(args.str,
                        args.from,
                        args.to),

    asciiUpper:
      local params = [
        { id: 'str' },
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
        std.asciiUpper(args.str),

    asciiLower:
      local params = [
        { id: 'str' },
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
        std.asciiLower(args.str),

    range:
      local params = [
        { id: 'from' },
        { id: 'to' },
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
        std.range(args.from,
                  args.to),

    repeat:
      local params = [
        { id: 'what' },
        { id: 'count' },
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
        std.repeat(args.what,
                   args.count),

    slice:
      local params = [
        { id: 'indexable' },
        { id: 'index' },
        { id: 'end' },
        { id: 'step' },
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
        std.slice(args.indexable,
                  args.index,
                  args.end,
                  args.step),

    member:
      local params = [
        { id: 'arr' },
        { id: 'x' },
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
        std.member(args.arr,
                   args.x),

    count:
      local params = [
        { id: 'arr' },
        { id: 'x' },
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
        std.count(args.arr,
                  args.x),

    mod:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.mod(args.a,
                args.b),

    deg2rad:
      local params = [
        { id: 'x' },
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
        std.deg2rad(args.x),

    rad2deg:
      local params = [
        { id: 'x' },
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
        std.rad2deg(args.x),

    log2:
      local params = [
        { id: 'x' },
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
        std.log2(args.x),

    log10:
      local params = [
        { id: 'x' },
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
        std.log10(args.x),

    map:
      local params = [
        { id: 'func' },
        { id: 'arr' },
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
        std.map(function(x)
                  callAnonymous(args.func, [x], env, locals)
                ,
                args.arr),

    mapWithIndex:
      local params = [
        { id: 'func' },
        { id: 'arr' },
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
        std.mapWithIndex(function(i, x)
                           callAnonymous(args.func, [i, x], env, locals)
                         ,
                         args.arr),

    mapWithKey:
      local params = [
        { id: 'func' },
        { id: 'obj' },
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
        std.mapWithKey(function(key, value)
                         callAnonymous(args.func, [key, value], env, locals)
                       ,
                       args.obj),

    flatMap:
      local params = [
        { id: 'func' },
        { id: 'arr' },
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
        std.flatMap(function(x)
                      callAnonymous(args.func, [x], env, locals)
                    ,
                    args.arr),

    join:
      local params = [
        { id: 'sep' },
        { id: 'arr' },
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
        std.join(args.sep,
                 args.arr),

    lines:
      local params = [
        { id: 'arr' },
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
        std.lines(args.arr),

    deepJoin:
      local params = [
        { id: 'arr' },
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
        std.deepJoin(args.arr),

    format:
      local params = [
        { id: 'str' },
        { id: 'vals' },
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
        std.format(args.str,
                   args.vals),

    foldr:
      local params = [
        { id: 'func' },
        { id: 'arr' },
        { id: 'init' },
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
        std.foldr(function(item, acc)
                    callAnonymous(args.func, [item, acc], env, locals)
                  ,
                  args.arr,
                  args.init),

    foldl:
      local params = [
        { id: 'func' },
        { id: 'arr' },
        { id: 'init' },
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
        std.foldl(function(acc, item)
                    callAnonymous(args.func, [acc, item], env, locals)
                  ,
                  args.arr,
                  args.init),

    filterMap:
      local params = [
        { id: 'filter_func' },
        { id: 'map_func' },
        { id: 'arr' },
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
        std.filterMap(function(x)
                        callAnonymous(args.filter_func, [x], env, locals)
                      ,
                      function(x)
                        callAnonymous(args.map_func, [x], env, locals)
                      ,
                      args.arr),

    assertEqual:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.assertEqual(args.a,
                        args.b),

    abs:
      local params = [
        { id: 'n' },
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
        std.abs(args.n),

    sign:
      local params = [
        { id: 'n' },
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
        std.sign(args.n),

    max:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.max(args.a,
                args.b),

    min:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.min(args.a,
                args.b),

    clamp:
      local params = [
        { id: 'x' },
        { id: 'minVal' },
        { id: 'maxVal' },
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
        std.clamp(args.x,
                  args.minVal,
                  args.maxVal),

    flattenArrays:
      local params = [
        { id: 'arrs' },
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
        std.flattenArrays(args.arrs),

    flattenDeepArray:
      local params = [
        { id: 'value' },
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
        std.flattenDeepArray(args.value),

    manifestIni:
      local params = [
        { id: 'ini' },
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
        std.manifestIni(args.ini),

    manifestToml:
      local params = [
        { id: 'value' },
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
        std.manifestToml(args.value),

    manifestTomlEx:
      local params = [
        { id: 'value' },
        { id: 'indent' },
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
        std.manifestTomlEx(args.value,
                           args.indent),

    escapeStringJson:
      local params = [
        { id: 'str_' },
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
        std.escapeStringJson(args.str_),

    escapeStringPython:
      local params = [
        { id: 'str' },
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
        std.escapeStringPython(args.str),

    escapeStringBash:
      local params = [
        { id: 'str_' },
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
        std.escapeStringBash(args.str_),

    escapeStringDollars:
      local params = [
        { id: 'str_' },
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
        std.escapeStringDollars(args.str_),

    escapeStringXML:
      local params = [
        { id: 'str_' },
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
        std.escapeStringXML(args.str_),

    manifestJson:
      local params = [
        { id: 'value' },
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
        std.manifestJson(args.value),

    manifestJsonMinified:
      local params = [
        { id: 'value' },
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
        std.manifestJsonMinified(args.value),

    manifestJsonEx:
      local params = [
        { id: 'value' },
        { id: 'indent' },
        { id: 'newline', default: { string: '\\n', type: 'string' } },
        { id: 'key_val_sep', default: { string: ': ', type: 'string' } },
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
        std.manifestJsonEx(args.value,
                           args.indent,
                           args.newline,
                           args.key_val_sep),

    manifestYamlDoc:
      local params = [
        { id: 'value' },
        { id: 'indent_array_in_object', default: { boolean: 'false', type: 'boolean' } },
        { id: 'quote_keys', default: { boolean: 'true', type: 'boolean' } },
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
        std.manifestYamlDoc(args.value,
                            args.indent_array_in_object,
                            args.quote_keys),

    manifestYamlStream:
      local params = [
        { id: 'value' },
        { id: 'indent_array_in_object', default: { boolean: 'false', type: 'boolean' } },
        { id: 'c_document_end', default: { boolean: 'true', type: 'boolean' } },
        { id: 'quote_keys', default: { boolean: 'true', type: 'boolean' } },
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
        std.manifestYamlStream(args.value,
                               args.indent_array_in_object,
                               args.c_document_end,
                               args.quote_keys),

    manifestPython:
      local params = [
        { id: 'v' },
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
        std.manifestPython(args.v),

    manifestPythonVars:
      local params = [
        { id: 'conf' },
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
        std.manifestPythonVars(args.conf),

    manifestXmlJsonml:
      local params = [
        { id: 'value' },
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
        std.manifestXmlJsonml(args.value),

    base64:
      local params = [
        { id: 'input' },
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
        std.base64(args.input),

    base64DecodeBytes:
      local params = [
        { id: 'str' },
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
        std.base64DecodeBytes(args.str),

    base64Decode:
      local params = [
        { id: 'str' },
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
        std.base64Decode(args.str),

    reverse:
      local params = [
        { id: 'arr' },
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
        std.reverse(args.arr),

    sort:
      local params = [
        { id: 'arr' },
        { id: 'keyF', default: id },
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
        std.sort(
          args.arr,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    uniq:
      local params = [
        { id: 'arr' },
        { id: 'keyF', default: id },
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
        std.uniq(
          args.arr,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    set:
      local params = [
        { id: 'arr' },
        { id: 'keyF', default: id },
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
        std.set(
          args.arr,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    setMember:
      local params = [
        { id: 'x' },
        { id: 'arr' },
        { id: 'keyF', default: id },
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
        std.setMember(
          args.x,
          args.arr,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    setUnion:
      local params = [
        { id: 'a' },
        { id: 'b' },
        { id: 'keyF', default: id },
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
        std.setUnion(
          args.a,
          args.b,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    setInter:
      local params = [
        { id: 'a' },
        { id: 'b' },
        { id: 'keyF', default: id },
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
        std.setInter(
          args.a,
          args.b,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    setDiff:
      local params = [
        { id: 'a' },
        { id: 'b' },
        { id: 'keyF', default: id },
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
        std.setDiff(
          args.a,
          args.b,
          function(x)
            callAnonymous(args.keyF, [x], env, locals)
        ),

    mergePatch:
      local params = [
        { id: 'target' },
        { id: 'patch' },
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
        std.mergePatch(args.target,
                       args.patch),

    get:
      local params = [
        { id: 'o' },
        { id: 'f' },
        { id: 'default', default: { literal: 'null', type: 'literal' } },
        { id: 'inc_hidden', default: { boolean: 'true', type: 'boolean' } },
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
        std.get(args.o,
                args.f,
                args.default,
                args.inc_hidden),

    objectFields:
      local params = [
        { id: 'o' },
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
        std.objectFields(args.o),

    objectFieldsAll:
      local params = [
        { id: 'o' },
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
        std.objectFieldsAll(args.o),

    objectHas:
      local params = [
        { id: 'o' },
        { id: 'f' },
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
        std.objectHas(args.o,
                      args.f),

    objectHasAll:
      local params = [
        { id: 'o' },
        { id: 'f' },
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
        std.objectHasAll(args.o,
                         args.f),

    objectValues:
      local params = [
        { id: 'o' },
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
        std.objectValues(args.o),

    objectValuesAll:
      local params = [
        { id: 'o' },
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
        std.objectValuesAll(args.o),

    objectKeysValues:
      local params = [
        { id: 'o' },
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
        std.objectKeysValues(args.o),

    objectKeysValuesAll:
      local params = [
        { id: 'o' },
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
        std.objectKeysValuesAll(args.o),

    equals:
      local params = [
        { id: 'a' },
        { id: 'b' },
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
        std.equals(args.a,
                   args.b),

    resolvePath:
      local params = [
        { id: 'f' },
        { id: 'r' },
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
        std.resolvePath(args.f,
                        args.r),

    prune:
      local params = [
        { id: 'a' },
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
        std.prune(args.a),

    findSubstr:
      local params = [
        { id: 'pat' },
        { id: 'str' },
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
        std.findSubstr(args.pat,
                       args.str),

    find:
      local params = [
        { id: 'value' },
        { id: 'arr' },
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
        std.find(args.value,
                 args.arr),

    all:
      local params = [
        { id: 'arr' },
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
        std.all(args.arr),

    any:
      local params = [
        { id: 'arr' },
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
        std.any(args.arr),

    __compare:
      local params = [
        { id: 'v1' },
        { id: 'v2' },
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
        std.__compare(args.v1,
                      args.v2),

    __compare_array:
      local params = [
        { id: 'arr1' },
        { id: 'arr2' },
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
        std.__compare_array(args.arr1,
                            args.arr2),

    __array_less:
      local params = [
        { id: 'arr1' },
        { id: 'arr2' },
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
        std.__array_less(args.arr1,
                         args.arr2),

    __array_greater:
      local params = [
        { id: 'arr1' },
        { id: 'arr2' },
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
        std.__array_greater(args.arr1,
                            args.arr2),

    __array_less_or_equal:
      local params = [
        { id: 'arr1' },
        { id: 'arr2' },
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
        std.__array_less_or_equal(args.arr1,
                                  args.arr2),

    __array_greater_or_equal:
      local params = [
        { id: 'arr1' },
        { id: 'arr2' },
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
        std.__array_greater_or_equal(args.arr1,
                                     args.arr2),

    sum:
      local params = [
        { id: 'arr' },
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
        std.sum(args.arr),

    avg:
      local params = [
        { id: 'arr' },
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
        std.avg(args.arr),

    minArray:
      local params = [
        { id: 'arr' },
        { id: 'keyF', default: id },
        { id: 'onEmpty', default: { expr: { string: 'Expected at least one element in array. Got none', type: 'string' }, type: 'error_expr' } },
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
        std.minArray(args.arr,
                     function(x)
                       callAnonymous(args.keyF, [x], env, locals)
                     ,
                     args.onEmpty),

    maxArray:
      local params = [
        { id: 'arr' },
        { id: 'keyF', default: id },
        { id: 'onEmpty', default: { expr: { string: 'Expected at least one element in array. Got none', type: 'string' }, type: 'error_expr' } },
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
        std.maxArray(args.arr,
                     function(x)
                       callAnonymous(args.keyF, [x], env, locals)
                     ,
                     args.onEmpty),

    xor:
      local params = [
        { id: 'x' },
        { id: 'y' },
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
        std.xor(args.x,
                args.y),

    xnor:
      local params = [
        { id: 'x' },
        { id: 'y' },
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
        std.xnor(args.x,
                 args.y),

    round:
      local params = [
        { id: 'x' },
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
        std.round(args.x),

    isEmpty:
      local params = [
        { id: 'str' },
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
        std.isEmpty(args.str),

    contains:
      local params = [
        { id: 'arr' },
        { id: 'elem' },
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
        std.contains(args.arr,
                     args.elem),

    equalsIgnoreCase:
      local params = [
        { id: 'str1' },
        { id: 'str2' },
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
        std.equalsIgnoreCase(args.str1,
                             args.str2),

    isEven:
      local params = [
        { id: 'x' },
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
        std.isEven(args.x),

    isOdd:
      local params = [
        { id: 'x' },
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
        std.isOdd(args.x),

    isInteger:
      local params = [
        { id: 'x' },
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
        std.isInteger(args.x),

    isDecimal:
      local params = [
        { id: 'x' },
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
        std.isDecimal(args.x),

    removeAt:
      local params = [
        { id: 'arr' },
        { id: 'at' },
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
        std.removeAt(args.arr,
                     args.at),

    remove:
      local params = [
        { id: 'arr' },
        { id: 'elem' },
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
        std.remove(args.arr,
                   args.elem),

    objectRemoveKey:
      local params = [
        { id: 'obj' },
        { id: 'key' },
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
        std.objectRemoveKey(args.obj,
                            args.key),

    sha1:
      local params = [
        { id: 'str' },
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
        std.sha1(args.str),

    sha256:
      local params = [
        { id: 'str' },
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
        std.sha256(args.str),

    sha512:
      local params = [
        { id: 'str' },
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
        std.sha512(args.str),

    sha3:
      local params = [
        { id: 'str' },
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
        std.sha3(args.str),

    trim:
      local params = [
        { id: 'str' },
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
        std.trim(args.str),

    acos:
      local params = [
        { id: 'x' },
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
        std.acos(args.x),

    asin:
      local params = [
        { id: 'x' },
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
        std.asin(args.x),

    atan:
      local params = [
        { id: 'x' },
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
        std.atan(args.x),

    atan2:
      local params = [
        { id: 'x' },
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
        std.atan2(args.x),

    ceil:
      local params = [
        { id: 'x' },
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
        std.ceil(args.x),

    char:
      local params = [
        { id: 'n' },
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
        std.char(args.n),

    codepoint:
      local params = [
        { id: 'str' },
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
        std.codepoint(args.str),

    cos:
      local params = [
        { id: 'x' },
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
        std.cos(args.x),

    decodeUTF8:
      local params = [
        { id: 'arr' },
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
        std.decodeUTF8(args.arr),

    encodeUTF8:
      local params = [
        { id: 'str' },
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
        std.encodeUTF8(args.str),

    exp:
      local params = [
        { id: 'x' },
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
        std.exp(args.x),

    exponent:
      local params = [
        { id: 'x' },
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
        std.exponent(args.x),

    extVar:
      local params = [
        { id: 'x' },
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
        std.extVar(args.x),

    filter:
      local params = [
        { id: 'func' },
        { id: 'arr' },
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
        std.filter(function(x)
                     callAnonymous(args.func, [x], env, locals)
                   ,
                   args.arr),

    floor:
      local params = [
        { id: 'x' },
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
        std.floor(args.x),

    id:
      local params = [
        { id: 'x' },
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
        std.id(args.x),

    length:
      local params = [
        { id: 'x' },
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
        std.length(args.x),

    log:
      local params = [
        { id: 'x' },
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
        std.log(args.x),

    makeArray:
      local params = [
        { id: 'sz' },
        { id: 'func' },
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
        std.makeArray(
          args.sz,
          function(x)
            callAnonymous(args.func, [x], env, locals)
        ),

    mantissa:
      local params = [
        { id: 'x' },
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
        std.mantissa(args.x),

    md5:
      local params = [
        { id: 's' },
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
        std.md5(args.s),

    modulo:
      local params = [
        { id: 'x' },
        { id: 'y' },
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
        std.modulo(args.x,
                   args.y),

    native:
      local params = [
        { id: 'x' },
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
        std.native(args.x),

    objectFieldsEx:
      local params = [
        { id: 'obj' },
        { id: 'hidden' },
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
        std.objectFieldsEx(args.obj,
                           args.hidden),

    objectHasEx:
      local params = [
        { id: 'obj' },
        { id: 'fname' },
        { id: 'hidden' },
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
        std.objectHasEx(args.obj,
                        args.fname,
                        args.hidden),

    parseJson:
      local params = [
        { id: 'str' },
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
        std.parseJson(args.str),

    parseYaml:
      local params = [
        { id: 'x' },
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
        std.parseYaml(args.x),

    pow:
      local params = [
        { id: 'x' },
        { id: 'n' },
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
        std.pow(args.x,
                args.n),

    primitiveEquals:
      local params = [
        { id: 'x' },
        { id: 'y' },
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
        std.primitiveEquals(args.x,
                            args.y),

    sin:
      local params = [
        { id: 'x' },
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
        std.sin(args.x),

    sqrt:
      local params = [
        { id: 'x' },
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
        std.sqrt(args.x),

    strReplace:
      local params = [
        { id: 'str' },
        { id: 'from' },
        { id: 'to' },
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
        std.strReplace(args.str,
                       args.from,
                       args.to),

    tan:
      local params = [
        { id: 'x' },
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
        std.tan(args.x),

    thisFile:
      local params = [
        { id: 'x' },
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
        std.thisFile(args.x),

    trace:
      local params = [
        { id: 'str' },
        { id: 'rest' },
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
        std.trace(args.str,
                  args.rest),

    type:
      local params = [
        { id: 'x' },
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
        std.type(args.x),

  }
