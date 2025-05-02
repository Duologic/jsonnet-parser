local parser = import './parser.libsonnet';

local callAnonymous(args, callparams) =
  args.func.call(
    std.foldr(
      function(i, callargs)
        callargs + { [args.func.params[i].id]: callparams[i] },
      std.range(0, std.length(callparams) - 1),
      {}
    )
  );

{
  local evaluator = self,

  std:
    //(import './std-builtin.jsonnet')
    (import './std-in-jsonnet-render.libsonnet')
    //+ (evaluator + { std: {} }).new('std', importstr './std.jsonnet').eval()
    + {
      //base64Decode: {
      //  params: [
      //    { id: 'x' },
      //  ],
      //  call(args):
      //    std.base64Decode(args.x),
      //},
      //base64DecodeBytes: {
      //  params: [
      //    { id: 'x' },
      //  ],
      //  call(args):
      //    std.base64DecodeBytes(args.x),
      //},
      join: {
        params: [
          { id: 'sep' },
          { id: 'arr' },
        ],
        call(args):
          std.join(args.sep, args.arr),
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
      makeArray: {
        params: [
          { id: 'sz' },
          { id: 'func' },
        ],
        call(args):
          std.makeArray(
            args.sz,
            function(item)
              callAnonymous(args, [item]),
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
            std.get(
              {
                array: args.arr,
                string: std.stringChars(args.arr),
              },
              std.type(args.arr),
              error 'unexpected type: ' + std.type(args.arr)
            ),
            args.init
          ),
      },
    },

  new(filename, file, imports={}): {
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
          std: evaluator.std + {
            thisFile: filename,
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
          'tailstrict': root.evalTailstrict,
        },
        expr.type,
        error 'Unexpected type: ' + expr.type
      )(expr, env, locals),

    evalLiteral(expr, env, locals):
      env[expr[expr.type]],

    evalNumber(expr, env, locals):
      local pointLoc = std.findSubstr('.', expr.number);
      std.parseJson(expr.number),
    //if std.length(pointLoc) == 0
    //then
    //else
    //  std.parseInt(std.strReplace(expr.number, '.', '')) / std.pow(10, pointLoc[0]),

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
      local isDollar = !std.objectHas(env, '$');
      local fieldsEval =
        local fieldsEnv = env + { 'self': fieldFunctionsEval, [if isDollar then '$']: self['self'] };
        std.foldr(
          function(field, acc)
            acc + root.evalField(field, fieldsEnv + { 'self'+: acc }, localEnv),
          fields,
          fieldFunctionsEval,
        );

      local assertions =
        local assertEnv = env + { 'self': fieldsEval, [if isDollar then '$']: self['self'] };
        std.filterMap(
          function(member)
            member.type == 'assertion'
            && !root.evalExpr(member.expr, assertEnv, localEnv),
          function(assertion)
            // TODO: return file:location and stack trace
            root.evalAssertion(assertion, {}, assertEnv, localEnv),
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
        if root.evalExpr(exprs[0], env, locals) == 'self'
        then env['self']
        else if std.get(exprs[0], 'literal', '') == '$'
        then env['$']
        else root.evalExpr(exprs[0], env, locals);

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
              then { [param.id]: param.default(locals + self) }
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

    // Good test case: builtinBase64Decode.jsonnet
    evalBinary(expr, env, locals):
      local precedence = [
        '*',
        '/',
        '%',
        '+',
        '-',
        '<<',
        '>>',
        '<',
        '>',
        '<=',
        '>=',
        'in',
        '==',
        '!=',
        '&',
        '^',
        '|',
        '&&',
        '||',
      ];

      local doOperation(tuple, superleft={}) =
        local left =
          if std.isArray(tuple[0])
          then doOperation(tuple[0], superleft)
          else root.evalExpr(tuple[0], env + { 'super'+: superleft }, locals);
        local binaryop = tuple[1];
        local right =
          if std.isArray(tuple[2])
          then doOperation(tuple[2], superleft + left)
          else root.evalExpr(tuple[2], env + { 'super'+: superleft + left }, locals);

        std.get(
          {
            '*': left * right,
            '/': left / right,
            '%': left % right,
            '+': left + right,
            '-': left - right,
            '<<': left << right,
            '>>': left >> right,
            '<': left < right,
            '<=': left <= right,
            '>': left > right,
            '>=': left >= right,
            '==': left == right,
            '!=': left != right,
            'in': left in right,
            '&': left & right,
            '^': left ^ right,
            '|': left | right,
            '&&': left && right,
            '||': left || right,
          },
          binaryop,
          error 'Unexpected operator: ' + binaryop
        );

      local serializeBinaryOp(expr) =
        [
          expr.left_expr,
          expr.binaryop,
        ]
        + (
          if expr.right_expr.type == 'binary'
          then serializeBinaryOp(expr.right_expr)
          else [expr.right_expr]
        );

      local makeTuples(series) =
        local index = std.find(series[1], precedence)[0];
        local indexNext = std.find(series[3], precedence)[0];
        if std.length(series) < 4  // last one
        then series
        else if index < indexNext
        then
          makeTuples(
            [
              series[0:3],
            ]
            + series[3:]
          )
        else
          series[0:2]
          + [
            makeTuples(
              series[2:]
            ),
          ];

      std.foldl(
        function(acc, fn)
          fn(acc),
        [
          serializeBinaryOp,
          makeTuples,
          doOperation,
        ],
        expr
      ),

    evalUnary(expr, env, locals):
      // unary takes precedence over binary
      if expr.expr.type == 'binary'
      then
        root.evalExpr(
          expr.expr
          + {
            left_expr: {
              type: 'unary',
              unaryop: expr.unaryop,
              expr: expr.expr.left_expr,
            },
          },
          env,
          locals
        )
      else
        local eval = root.evalExpr(expr.expr, env, locals);
        std.get(
          {
            '-': -eval,
            '+': +eval,
            '!': !eval,
            '~': ~eval,
          },
          expr.unaryop,
          error 'Unexpected operator: ' + expr.binaryop
        ),

    evalImplicitPlus(expr, env, locals):
      local left = root.evalExpr(expr.expr, env, locals);
      local right = root.evalExpr(expr.object, env + { 'super': left }, locals);
      left + right,

    evalAnonymousFunction(fn, env, locals): {
      params:
        std.map(
          function(param)
            {
              id: param.id.id,
              [if std.objectHas(param, 'expr') then 'default'](callLocals):
                root.evalExpr(
                  param.expr,
                  env,
                  locals + callLocals
                ),
            },
          fn.params.params
        ),
      call(args):
        root.evalExpr(fn.expr, env, locals + args),
    },

    evalAssertionExpr(expr, env, locals):
      local expression = root.evalExpr(expr.expression, env, locals);
      root.evalAssertion(expr.assertion, expression, env, locals),

    evalAssertion(assertion, expression, env, locals):
      (
        if std.objectHas(assertion, 'return_expr')
        then
          assert
            root.evalExpr(assertion.expr, env, locals)
            : root.evalExpr(assertion.return_expr, env, locals);
          expression
        else
          assert
            root.evalExpr(assertion.expr, env, locals) : std.manifestJson(assertion.expr);
          expression
      ),

    evalImportStatement(expr, env, locals):
      local imp = imports[expr.path];
      if std.isString(imp)
      then
        local parsed = parser.new(imp).parse();
        evaluator.new(expr.path, parsed, imports).eval()
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

    evalTailstrict(expr, env, locals):
      root.evalExpr(expr.expr, env, locals) tailstrict,

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

      local isDollar = !std.objectHas(env, '$');
      local fieldEval(this) =
        root.evalExpr(
          field.expr,
          env + { 'self'+: this, parentIsHidden: h == '::', [if isDollar then '$']+: this },
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
      // FIXME: throw error
      //assert std.get(env, 'parentIsHidden', false) || op == '::' : "couldn't manifest function as JSON";
      local isDollar = !std.objectHas(env, '$');
      {
        local this = self,
        [fieldname]: {
          params: std.map(
            function(param)
              {
                id: param.id.id,
                [if std.objectHas(param, 'expr') then 'default'](callLocals):
                  root.evalExpr(
                    param.expr,
                    env + { 'self'+: this, [if isDollar then '$']+: this },
                    locals + callLocals
                  ),
              },
            field.params.params
          ),
          call(args)::
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
              [if std.objectHas(param, 'expr') then 'default'](callLocals):
                root.evalExpr(
                  param.expr,
                  env,
                  locals + this + callLocals
                ),
            },
          bind.params.params
        ),
        call(args):
          root.evalExpr(bind.expr, env, locals + this + args),
      },
    },
  },
}
