local parser = import './parser.libsonnet';

{
  local evaluator = self,
  new(file, imports={
    //std: importstr './std.jsonnet',
  }): {
    local root = self,
    local expr =
      if std.isString(file)
      then
        // parse file if it is a string
        //parser.new("local std = import 'std';" + file).parse()
        parser.new(file).parse()
      else
        // assume file is already parsed
        file,

    eval():
      root.evalExpr(
        expr,
        env={
          'null': null,
          'true': true,
          'false': false,
        },
        locals={
          std: {
            local callAnonymous(args, callparams) =
              args.func.call(
                std.foldr(
                  function(i, callargs)
                    callargs + { [args.func.params[i].id]: callparams[i] },
                  std.range(0, std.length(callparams) - 1),
                  {}
                )
              ),
            trace: {
              params: [
                { id: 'str' },
                { id: 'rest' },
              ],
              call(args):
                std.trace(args.str, args.rest),
            },
            range: {
              params: [
                { id: 'from' },
                { id: 'to' },
              ],
              call(args):
                std.range(args.from, args.to),
            },
            map: {
              params: [
                { id: 'func' },
                { id: 'arr' },
              ],
              call(args):
                std.map(
                  function(item)
                    callAnonymous(args, [item]),
                  args.arr
                ),
            },
            flatMap: {
              params: [
                { id: 'func' },
                { id: 'arr' },
              ],
              call(args):
                std.flatMap(
                  function(item)
                    callAnonymous(args, [item]),
                  args.arr
                ),
            },
            filter: {
              params: [
                { id: 'func' },
                { id: 'arr' },
              ],
              call(args):
                std.filter(
                  function(item)
                    callAnonymous(args, [item]),
                  args.arr
                ),
            },
            foldr: {
              params: [
                { id: 'func' },
                { id: 'arr' },
                { id: 'init' },
              ],
              call(args):
                std.foldr(
                  function(item, acc)
                    callAnonymous(args, [item, acc]),
                  args.arr,
                  args.init
                ),
            },
          },
        }
      ),

    evalExpr(expr, env, locals):
      std.get(
        {
          literal: root.evalLiteral,
          boolean: root.evalLiteral,
          number: root.evalNumber,
          string: root.evalString,
          parenthesis: root.evalParenthesis,
          object: root.evalObject,
          object_forloop: root.evalObjectForloop,
          array: root.evalArray,
          forloop: root.evalForloop,
          fieldaccess: root.evalFieldaccess,
          indexing: root.evalIndexing,
          fieldaccess_super: root.evalFieldaccessSuper,
          indexing_super: root.evalIndexingSuper,
          functioncall: root.evalFunctioncall,
          id: root.evalIdentifier,
          local_bind: root.evalLocalBind,
          conditional: root.evalConditional,
          binary: root.evalBinary,
          unary: root.evalUnary,
          implicit_plus: root.evalImplicitPlus,
          anonymous_function: root.evalAnonymousFunction,
          assertion_expr: root.evalAssertionExpr,
          import_statement: root.evalImportStatement,
          importstr_statement: root.evalImportStrStatement,
          importbin_statement: root.evalImportBinStatement,
          error_expr: root.evalErrorExpr,
          expr_in_super: root.evalExprInSuper,
        },
        expr.type,
        error 'Unexpected type: ' + expr.type
      )(expr, env, locals),

    evalLiteral(expr, env, locals):
      env[expr[expr.type]],

    evalNumber(expr, env, locals):
      local pointLoc = std.findSubstr('.', expr.number);
      if std.length(pointLoc) == 0
      then std.parseInt(expr.number)
      else
        std.parseInt(std.strReplace(expr.number, '.', '')) / std.pow(10, pointLoc[0]),

    evalString(expr, env, locals):
      expr.string,

    evalParenthesis(expr, env, locals):
      root.evalExpr(expr.expr, env, locals),

    evalObject(expr, env, locals):
      local binds =
        std.filterMap(
          function(member)
            member.type == 'object_local',
          function(member)
            member.bind,
          expr.members
        );
      local localEnv = root.evalBinds(binds, env, locals);

      local fieldFunctions =
        std.filter(
          function(member)
            member.type == 'field_function',
          expr.members
        );
      local fieldFunctionsEval =
        std.foldr(
          function(field, acc)
            acc + root.evalFieldFunction(field, env, localEnv),
          fieldFunctions,
          {}
        );

      local fields =
        std.filter(
          function(member)
            member.type == 'field',
          expr.members
        );
      local fieldsEval =
        local fieldsEnv = env + { 'self': fieldFunctionsEval };
        std.foldr(
          function(field, acc)
            acc + root.evalField(field, fieldsEnv + { 'self'+: acc }, localEnv),
          fields,
          fieldFunctionsEval,
        );

      local assertions =
        local assertEnv = env + { 'self': fieldsEval };
        std.filterMap(
          function(member)
            member.type == 'assertion'
            && !root.evalExpr(member.expr, assertEnv, localEnv),
          function(assertion)
            // TODO: return file:location and stack trace
            assert root.evalExpr(assertion.expr, assertEnv, localEnv) :
                   root.evalExpr(assertion.return_expr, assertEnv, localEnv);
            {},
          expr.members
        );

      if assertions != []
      then assertions
      else fieldsEval,

    evalObjectForloop(expr, env, locals):
      local binds =
        std.map(
          function(objectLocal)
            objectLocal.bind,
          std.get(expr, 'left_object_locals', [])
          + std.get(expr, 'right_object_locals', []),
        );
      local localEnv = root.evalBinds(binds, env, locals);
      local forspec = root.evalForspec(expr.forspec, env, locals);
      std.foldl(
        function(acc, item)
          acc + root.evalField(
            expr.field,
            env,
            { [forspec.id]: item } + localEnv
          ),
        forspec.items,
        {},
      ),

    evalArray(expr, env, locals):
      std.map(
        function(item)
          root.evalExpr(item, env, locals),
        expr.items,
      ),

    evalForloop(expr, env, locals):
      local forspec = root.evalForspec(expr.forspec, env, locals);
      local compspec = root.evalCompspec(forspec, expr.compspec, env, locals);
      std.map(
        function(item)
          root.evalExpr(expr.expr, env, locals + item),
        compspec,
      ),

    evalFieldaccess(expr, env, locals):
      local flattenFieldaccess(e) =
        [e.id]
        + std.flatMap(
          function(expr)
            if expr.type == 'fieldaccess'
            then flattenFieldaccess(expr)
            else [expr],
          e.exprs
        );
      local exprs = std.reverse(flattenFieldaccess(expr));
      local lookup =
        std.get(
          {
            'self': env['self'],
          },
          std.get(exprs[0], 'id', ''),
          root.evalExpr(exprs[0], env, locals)
        );

      std.foldr(
        function(expr, locals)
          root.evalExpr(expr, env, locals),
        std.reverse(exprs[1:]),
        lookup,
      ),

    evalIndexing(expr, env, locals):
      local indexable = root.evalExpr(expr.expr, env, locals);
      std.get(
        {
          '1': indexable[
            root.evalExpr(expr.exprs[0], env, locals)
          ],
          '2': indexable[
            root.evalExpr(expr.exprs[0], env, locals)
            :root.evalExpr(expr.exprs[1], env, locals)
          ],
          '3': indexable[
            root.evalExpr(expr.exprs[0], env, locals)
            :root.evalExpr(expr.exprs[1], env, locals)
            :root.evalExpr(expr.exprs[2], env, locals)
          ],
        },
        std.toString(std.length(expr.exprs)),
        error 'unexpected'
      ),

    evalFieldaccessSuper(expr, env, locals):
      env['super'][expr.id.id],

    evalIndexingSuper(expr, env, locals):
      env['super'][root.evalExpr(expr.expr, env, locals)],

    evalFunctioncall(expr, env, locals):
      local fn = root.evalExpr(expr.expr, env, locals);
      local validParams = std.map(
        function(param) param.id,
        fn.params,
      );
      local givenArgs =
        std.foldr(
          function(index, acc)
            local arg = expr.args[index];
            acc + (
              if std.objectHas(arg, 'id')
              then {
                assert std.member(validParams, arg.id.id) : 'function has no parameter %s' % arg.id.id,
                assert !std.objectHas(acc, arg.id.id) : 'Argument %s already provided' % arg.id.id,
                [arg.id.id]: root.evalExpr(arg.expr, env, locals + acc),
              }
              else {
                [fn.params[index].id]:
                  root.evalExpr(expr.args[index].expr, env, locals),
              }
            ),
          std.range(0, std.length(expr.args) - 1),
          {},
        );

      local args =
        std.foldr(
          function(index, acc)
            local param = fn.params[index];
            acc + (
              if std.objectHas(givenArgs, param.id)
              then { [param.id]: givenArgs[param.id] }
              else if std.objectHas(param, 'default')
              then { [param.id]: param.default }
              else error 'Missing argument: ' + param.id
            ),
          std.range(0, std.length(fn.params) - 1),
          {},
        );
      assert std.isFunction(fn.call) : 'Unexpected type %s, expected function' % std.type(fn);
      fn.call(locals + args),

    evalIdentifier(expr, env, locals):
      std.get(
        locals,
        expr.id,
        error 'no such field: ' + expr.id
      ),

    evalLocalBind(expr, env, locals):
      local newlocals = root.evalBinds([expr.bind] + std.get(expr, 'additional_binds', []), env, locals);
      root.evalExpr(expr.expr, env, newlocals),

    evalConditional(expr, env, locals):
      if root.evalExpr(expr.if_expr, env, locals)
      then root.evalExpr(expr.then_expr, env, locals)
      else
        if std.objectHas(expr, 'else_expr')
        then root.evalExpr(expr.else_expr, env, locals),

    evalBinary(expr, env, locals):
      local getExprs(binaryop, expr, env) = (
        if expr.type == 'binary'
        then
          local left = root.evalExpr(expr.left_expr, env, locals);
          [{ binaryop: binaryop, expr: left }]
          + getExprs(expr.binaryop, expr.right_expr, env + { 'super': left })
        else
          [{ binaryop: binaryop, expr: root.evalExpr(expr, env, locals) }]
      );

      local left = root.evalExpr(expr.left_expr, env, locals);
      std.foldl(
        function(left, right)
          local leftEval = left;
          local rightEval = right.expr;
          std.get(
            {
              '+': leftEval + rightEval,
              '-': leftEval - rightEval,
              '*': leftEval * rightEval,
              '/': leftEval / rightEval,
              '&&': leftEval && rightEval,
              '||': leftEval || rightEval,
              '==': leftEval == rightEval,
              '!=': leftEval != rightEval,
            },
            right.binaryop,
            error 'Unexpected operator: ' + right.binaryop
          ),
        getExprs(expr.binaryop, expr.right_expr, env + { 'super': left }),
        left
      ),

    evalUnary(expr, env, locals):
      local eval = root.evalExpr(expr.expr, env, locals);
      std.get(
        {
          '!': !eval,
        },
        expr.unaryop,
        error 'Unexpected operator: ' + expr.binaryop
      ),

    evalImplicitPlus(expr, env, locals):
      local left = root.evalExpr(expr.expr, env, locals);
      local right = root.evalExpr(expr.object, env + { 'super': left });
      left + right,

    evalAnonymousFunction(fn, env, locals): {
      params: std.map(
        function(param)
          {
            id: param.id.id,
            [if std.objectHas(param, 'expr') then 'default']: root.evalExpr(param.expr, env, locals),
          },
        fn.params.params
      ),
      call(args):
        root.evalExpr(fn.expr, env, locals + args),
    },

    evalAssertionExpr(expr, env, locals):
      local assertion = root.evalExpr(expr.assertion.expr, env, locals);
      local expression = root.evalExpr(expr.expr, env, locals);
      (
        if std.objectHas(expr.assertion, 'return_expr')
        then
          assert
            assertion
            : root.evalExpr(expr.assertion.return_expr, env, locals);
          expression
        else
          assert
            root.evalExpr(expr.assertion.expr, env, locals);
          expression
      ),

    evalImportStatement(expr, env, locals):
      local imp = imports[expr.path];
      if std.isString(imp)
      then
        local parsed = parser.new(imp).parse();
        evaluator.new(parsed, imports).eval()
      else
        imp,

    evalImportStrStatement(expr, env, locals):
      imports[expr.path],

    evalImportBinStatement(expr, env, locals):
      imports[expr.path],

    evalErrorExpr(expr, env, locals):
      error root.evalExpr(expr.expr, env, locals),

    evalExprInSuper(expr, env, locals):
      root.evalExpr(expr.expr, env, locals) in env['super'],

    evalField(field, env, locals):
      local fieldname = root.evalFieldname(field.fieldname, env, locals);
      local additive =
        (
          if std.get(field, 'additive', false)
          then '+'
          else ''
        );
      local h = (
        if std.get(field, 'hidden', false)
        then '::'
        else field.h
      );
      local fieldEval(this) =
        root.evalExpr(
          field.expr,
          env + { 'self'+: this, parentIsHidden: h == '::' },
          locals,
        );
      std.get(
        {
          ':': {
            local this = self,
            assert field.type == 'field' : "couldn't manifest function as JSON",
            [fieldname]: fieldEval(this),
          },
          '::': {
            local this = self,
            [fieldname]:: fieldEval(this),
          },
          ':::': {
            local this = self,
            assert field.type == 'field' : "couldn't manifest function as JSON",
            [fieldname]::: fieldEval(this),
          },
          '+:': {
            local this = self,
            [fieldname]: fieldEval(this),
          },
          '+::': {
            local this = self,
            [fieldname]+:: fieldEval(this),
          },
          '+:::': {
            local this = self,
            [fieldname]+::: fieldEval(this),
          },
        },
        additive + h,
      ),

    evalFieldFunction(field, env, locals):
      local fieldname = root.evalFieldname(field.fieldname, env, locals);
      local op =
        if std.get(field, 'hidden', false)
        then '::'
        else field.h;
      assert std.get(env, 'parentIsHidden', false) || op == '::' : "couldn't manifest function as JSON";
      {
        [fieldname]:: {
          params: std.map(
            function(param)
              {
                id: param.id.id,
                [if std.objectHas(param, 'expr') then 'default']: root.evalExpr(param.expr, env, locals),
              },
            field.params.params
          ),
          call(args):
            root.evalExpr(field.expr, env, locals + args),
        },
      },

    evalCompspec(forspec, compspec, env, locals):
      std.foldl(
        function(acc, fn)
          fn(acc),
        [
          if spec.type == 'forspec'
          then
            function(acc)
              std.flatMap(
                function(item)
                  local forspec = root.evalForspec(spec, env, locals + item);
                  std.map(
                    function(i)
                      item + {
                        [forspec.id]: i,
                      },
                    forspec.items,
                  ),
                acc
              )
          else if spec.type == 'ifspec'
          then
            function(acc)
              std.filter(
                function(item)
                  root.evalExpr(spec.expr, env, locals + item),
                acc
              )
          else error 'unexpected'
          for spec in compspec.items
        ],
        std.map(
          function(i)
            { [forspec.id]: i },
          forspec.items,
        ),
      ),

    evalForspec(forspec, env, locals): {
      id: forspec.id.id,
      items: root.evalExpr(forspec.expr, env, locals),
    },

    evalFieldname(fieldname, env, locals):
      if fieldname.type == 'fieldname_expr'
      then root.evalExpr(fieldname.expr, env, locals)
      else fieldname[fieldname.type],

    evalBinds(binds, env, locals):
      std.foldr(
        function(bind, acc)
          acc + std.get(
            {
              bind: root.evalBind,
              bind_function: root.evalBindFunction,
            },
            bind.type,
            error 'Unexpected type: ' + bind.type,
          )(bind, env, locals + acc),
        binds,
        locals,
      ),

    evalBind(bind, env, locals): {
      [bind.id.id]: root.evalExpr(bind.expr, env, locals + self),
    },

    evalBindFunction(bind, env, locals): {
      local this = self,
      [bind.id.id]: {
        params: std.map(
          function(param)
            {
              id: param.id.id,
              [if std.objectHas(param, 'expr') then 'default']:
                root.evalExpr(param.expr, env, locals + this),
            },
          bind.params.params
        ),
        call(args):
          root.evalExpr(bind.expr, env, locals + this.args),
      },
    },
  },
}
