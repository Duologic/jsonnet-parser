local parser = import './parser.libsonnet';

local evaluator = {
  new(expr): {
    local root = self,
    eval():
      root.evalExpr(expr),

    evalExpr(expr, env={
      'null': null,
      'true': true,
      'false': false,
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
    }):
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
          functioncall: root.evalFunctioncall,
          id: root.evalIdentifier,
          local_bind: root.evalLocalBind,
          conditional: root.evalConditional,
          binary: root.evalBinary,
          unary: root.evalUnary,
          anonymous_function: root.evalAnonymousFunction,
        },
        expr.type,
        error 'Unexpected type: ' + expr.type
      )(expr, env),

    evalLiteral(expr, env):
      env[expr[expr.type]],

    evalNumber(expr, env):
      local pointLoc = std.findSubstr('.', expr.number);
      if std.length(pointLoc) == 0
      then std.parseInt(expr.number)
      else
        std.parseInt(std.strReplace(expr.number, '.', '')) / std.pow(10, pointLoc[0]),

    evalString(expr, env):
      expr.string,

    evalParenthesis(expr, env):
      root.evalExpr(expr.expr, env),

    evalObject(expr, env):
      local binds =
        std.filterMap(
          function(member)
            member.type == 'object_local',
          function(member)
            member.bind,
          expr.members
        );
      local localEnv = root.evalBinds(binds, env);

      local fieldFunctions =
        std.filter(
          function(member)
            member.type == 'field_function',
          expr.members
        );
      local fieldFunctionsEval =
        std.foldr(
          function(field, acc)
            acc + root.evalFieldFunction(field, env),
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
        local fieldsEnv = env + localEnv + { 'self': fieldFunctionsEval };
        std.foldr(
          function(field, acc)
            acc + root.evalField(field, fieldsEnv + { 'self'+: acc }),
          fields,
          {}
        );

      local assertions =
        local assertEnv = env + localEnv + { 'self': fieldsEval };
        std.filterMap(
          function(member)
            member.type == 'assertion'
            && !root.evalExpr(member.expr, assertEnv),
          function(assertion)
            // TODO: return file:location and stack trace
            assert root.evalExpr(assertion.expr, assertEnv) : root.evalExpr(assertion.return_expr, assertEnv);
            {},
          expr.members
        );

      if assertions != []
      then assertions
      else fieldsEval,

    evalObjectForloop(expr, env):
      local binds =
        std.map(
          function(objectLocal)
            objectLocal.bind,
          std.get(expr, 'left_object_locals', [])
          + std.get(expr, 'right_object_locals', []),
        );
      local localEnv = root.evalBinds(binds, env);
      local forspec = root.evalForspec(expr.forspec, env);
      std.foldl(
        function(acc, item)
          acc + root.evalField(expr.field, env + { [forspec.id]: item } + localEnv),
        forspec.items,
        {},
      ),

    evalArray(expr, env):
      std.map(
        function(item)
          root.evalExpr(item, env),
        expr.items,
      ),

    evalForloop(expr, env):
      local forspec = root.evalForspec(expr.forspec, env);
      local compspec = root.evalCompspec(forspec, expr.compspec, env);
      std.map(
        function(item)
          root.evalExpr(expr.expr, env + item),
        compspec,
      ),

    evalForspec(forspec, env): {
      id: forspec.id.id,
      items: root.evalExpr(forspec.expr, env),
    },

    evalCompspec(forspec, compspec, env):
      std.foldl(
        function(acc, fn)
          fn(acc),
        [
          if spec.type == 'forspec'
          then
            function(acc)
              std.flatMap(
                function(item)
                  local forspec = root.evalForspec(spec, env + item);
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
                  root.evalExpr(spec.expr, env + item),
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

    evalField(field, env):
      local fieldname = root.evalFieldname(field.fieldname, env);
      local fieldEval(this) = root.evalExpr(field.expr, env + { 'self'+: this });
      local op =
        (
          if std.get(field, 'additive', false)
          then '+'
          else ''
        )
        + (
          if std.get(field, 'hidden', false)
          then '::'
          else field.h
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
        op,
      ),

    evalFieldFunction(field, env):
      local fieldname = root.evalFieldname(field.fieldname, env);
      local op =
        if std.get(field, 'hidden', false)
        then '::'
        else field.h;
      assert op == '::' : "couldn't manifest function as JSON";
      {
        [fieldname]: {
          params: std.map(
            function(param)
              {
                id: param.id.id,
                [if std.objectHas(param, 'expr') then 'default']: root.evalExpr(param.expr, env),
              },
            field.params.params
          ),
          call(args):
            root.evalExpr(field.expr, env + args),
        },
      },

    evalFieldname(fieldname, env):
      if fieldname.type == 'fieldname_expr'
      then root.evalExpr(fieldname.expr, env)
      else fieldname[fieldname.type],

    evalBind(bind, env): {
      [bind.id.id]: root.evalExpr(bind.expr, env + self),
    },

    evalBindFunction(bind, env): {
      local this = self,
      [bind.id.id]: {
        params: std.map(
          function(param)
            {
              id: param.id.id,
              [if std.objectHas(param, 'expr') then 'default']: root.evalExpr(param.expr, env + this),
            },
          bind.params.params
        ),
        call(args):
          root.evalExpr(bind.expr, env + this + args),
      },
    },

    evalAnonymousFunction(fn, env): {
      params: std.map(
        function(param)
          {
            id: param.id.id,
            [if std.objectHas(param, 'expr') then 'default']: root.evalExpr(param.expr, env),
          },
        fn.params.params
      ),
      call(args):
        root.evalExpr(fn.expr, env + args),
    },

    evalFieldaccess(expr, env):
      std.foldr(
        root.evalExpr,
        [expr.id] + expr.exprs,
        env,
      ),

    evalFunctioncall(expr, env):
      local fn = root.evalExpr(expr.expr, env);
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
                [arg.id.id]: root.evalExpr(arg.expr, env + acc),
              }
              else {
                [fn.params[index].id]:
                  root.evalExpr(expr.args[index].expr, env),
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
      fn.call(env + args),

    evalIdentifier(expr, env):
      env[expr.id],

    evalBinds(binds, env):
      std.foldr(
        function(bind, acc)
          acc + std.get(
            {
              bind: root.evalBind,
              bind_function: root.evalBindFunction,
            },
            bind.type,
            error 'Unexpected type: ' + bind.type,
          )(bind, env + acc),
        binds,
        env,
      ),

    evalLocalBind(expr, env):
      local newenv = root.evalBinds([expr.bind] + std.get(expr, 'additional_binds', []), env);
      root.evalExpr(expr.expr, newenv),

    evalConditional(expr, env):
      if root.evalExpr(expr.if_expr)
      then root.evalExpr(expr.then_expr)
      else
        if std.objectHas(expr, 'else_expr')
        then root.evalExpr(expr.else_expr),

    evalBinary(expr, env):
      local getExprs(binaryop, expr) = (
        if expr.type == 'binary'
        then
          [{ binaryop: binaryop, expr: root.evalExpr(expr.left_expr, env) }]
          + getExprs(expr.binaryop, expr.right_expr)
        else
          [{ binaryop: binaryop, expr: root.evalExpr(expr, env) }]
      );

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
        getExprs(expr.binaryop, expr.right_expr),
        root.evalExpr(expr.left_expr, env)
      ),

    evalUnary(expr, env):
      local eval = root.evalExpr(expr.expr, env);
      std.get(
        {
          '!': !eval,
        },
        expr.unaryop,
        error 'Unexpected operator: ' + expr.binaryop
      ),
  },
};

local example = parser.new((importstr './eval_example.libsonnet')).parse();
//(import './eval_example.libsonnet') ==
//local example = parser.new('abc(aa="dd")').parse();
//example
evaluator.new(example).eval()
