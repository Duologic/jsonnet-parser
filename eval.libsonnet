local parser = import './parser.libsonnet';

{
  local evaluator = self,

  std: (import './std-in-jsonnet-render.libsonnet'),
  // slower to evaluate std.jsonnet but it is a good stress test for the evaluator
  //+ (evaluator + { std: {} }).new('std', importstr './std.jsonnet').eval(),

  new(filename, file, imports={}): {
    local root = self,
    local expr =
      if std.isString(file)
      then
        // parse file if it is a string
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
          inObject: false,
        },
        locals={
          std: evaluator.std(root) + {
            thisFile: filename,

            length:
              local params = [
                { id: 'x' },
              ];
              function(callArgs, env, locals, evalExpr=root.evalExpr)
                local args = root.evalArgs(
                  params,
                  env,
                  locals,
                  callArgs,
                  env,
                  locals,
                  evalExpr,
                );
                // FIXME: this makes tests succeed but doesn't when function is wrapped in parenthesis
                // example: `std.length((function(x,y) 42))`
                if std.type(args.x) == 'function'
                then std.length(callArgs[0].expr.params)
                else std.length(args.x),
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
          anonymous_function: root.evalFunction,
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

    evalString(expr, env, locals):
      if std.get(expr, 'textblock', false)
      then expr.string + '\n'
      else expr.string,

    evalParenthesis(expr, env, locals):
      root.evalExpr(expr.expr, env, locals),

    evalObject(expr, env, locals): {
      local objEnv = env
                     + {
                       inObject: true,
                       'self': result + std.get(env, 'right', {}),
                       [if !std.get(env, 'inBinary', false) then 'super']: {},
                     },

      local binds =
        std.filterMap(
          function(member)
            member.type == 'object_local',
          function(member)
            member.bind,
          expr.members
        ),

      local objLocals = locals + root.evalBinds(binds, objEnv, locals),

      local fieldFunctions =
        std.filter(
          function(member)
            member.type == 'field_function',
          expr.members
        ),
      local fieldFunctionsEval =
        std.foldr(
          function(field, acc)
            acc + root.evalFieldFunction(field, objEnv, objLocals),
          fieldFunctions,
          {}
        ),

      local fields =
        std.filter(
          function(member)
            member.type == 'field',
          expr.members
        ),
      local fieldsEval =
        std.foldr(
          function(field, acc)
            acc + root.evalField(field, objEnv, objLocals),
          fields,
          fieldFunctionsEval,
        ),

      local assertions =
        std.filter(
          function(member)
            member.type == 'assertion',
          expr.members
        ),

      local assertionFuncs =
        std.foldr(
          function(assertion, acc)
            acc + {
              assert root.evalExpr(
                assertion.expr,
                objEnv,
                objLocals,
              ) : (
                if std.objectHas(assertion, 'return_expr')
                then
                  root.evalExpr(
                    assertion.return_expr,
                    objEnv,
                    objLocals,
                  )
                else
                  'Assertion failed'
              ),
            },
          assertions,
          {},
        ),

      local result =
        fieldsEval
        + (
          if std.get(env, 'doAssertion', false)
          then assertionFuncs
          else {}
        ),

      result: result,
    }.result,

    evalObjectForloop(expr, env, locals):
      local binds =
        std.map(
          function(objectLocal)
            objectLocal.bind,
          std.get(expr, 'left_object_locals', [])
          + std.get(expr, 'right_object_locals', []),
        );
      local objLocals = root.evalBinds(binds, env, locals);
      local forspec = root.evalForspec(expr.forspec, env, locals);
      local compspec = root.evalCompspec(forspec, expr.compspec, env, locals);
      std.foldl(
        function(acc, item)
          acc + root.evalField(
            expr.field,
            env,
            locals + item + objLocals
          ),
        if std.objectHas(expr, 'compspec')
        then compspec
        else forspec,
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
        if std.objectHas(expr, 'compspec')
        then compspec
        else forspec,
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
        if std.get(exprs[0], 'literal', '') == 'self'
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
      local _indexable = root.evalExpr(expr.expr, env, locals);
      local indexable =
        if std.isString(_indexable)
        then std.stringChars(_indexable)
        else _indexable;
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
      assert std.isFunction(fn) : 'Unexpected type %s, expected function' % std.type(fn);
      local args =
        std.map(
          function(arg)
            {
              [if std.objectHas(arg, 'id') then 'id']: arg.id.id,
              expr: arg.expr,
            },
          expr.args
        );
      fn(args, env, locals),

    evalIdentifier(expr, env, locals):
      std.get(
        locals,
        expr.id,
        error 'no such field: ' + expr.id
      ),

    evalLocalBind(expr, env, locals):
      local newlocals = root.evalBinds(
        [expr.bind] + std.get(expr, 'additional_binds', []),
        env,
        locals
      );
      root.evalExpr(expr.expr, env, locals + newlocals),

    evalConditional(expr, env, locals):
      if root.evalExpr(expr.if_expr, env, locals)
      then root.evalExpr(expr.then_expr, env, locals)
      else
        if std.objectHas(expr, 'else_expr')
        then root.evalExpr(expr.else_expr, env, locals),

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

      local doOperation(tuple, opEnv=env) =
        local binaryop = tuple[1];
        local a = {
          local this = self,
          left(doAssertions):
            if std.isArray(tuple[0])
            then doOperation(tuple[0], opEnv)
            else root.evalExpr(
              tuple[0],
              opEnv + {
                doAssertions: doAssertions,
                [if binaryop == '+' then 'right']+: this.right(false),
              },
              locals
            ),
          right(doAssertions):
            if std.isArray(tuple[2])
            then doOperation(
              tuple[2],
              opEnv + {
                doAssertions: doAssertions,
                inBinary: true,
                [if binaryop == '+' then 'super']+: this.left(false),
                //[if binaryop == '+' then 'self']+: this.left,
              }
            )
            else root.evalExpr(
              tuple[2],
              opEnv + {
                doAssertions: doAssertions,
                inBinary: true,
                [if binaryop == '+' then 'super']+: this.left(false),
                //[if binaryop == '+' then 'self']+: this.left,
              },
              locals
            ),
        };
        local left = a.left(true);
        local right = a.right(true);

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

      // [["5", "*", "5"], "+", ["4", "*", "4"]]

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
      local binaryExpr = {
        type: 'binary',
        binaryop: '+',
        left_expr: expr.expr,
        right_expr: expr.object,
      };
      root.evalExpr(binaryExpr, env, locals),

    evalArgs(params, env, locals, callArgs, callEnv, callLocals, evalExpr):
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
          callArgs
        );
      assert std.length(callArgs) <= std.length(params)
             : 'Too many arguments' + expected;

      std.foldr(
        function(index, acc)
          local param = params[index];
          local findArg =
            std.filter(
              function(arg)
                std.objectHas(arg, 'id')
                && arg.id == param.id,
              validArgs,
            );

          acc + (
            // named argument (has id)
            if std.length(findArg) == 1
            then { [param.id]: evalExpr(findArg[0].expr, env, callLocals) }

            // positional argument (no id)
            else if index < std.length(validArgs)
                    && !std.objectHas(validArgs[index], 'id')
            then { [param.id]: evalExpr(validArgs[index].expr, env, callLocals) }

            // has a default value
            else if std.objectHas(param, 'default')
            then { [param.id]: evalExpr(param.default, env, locals + self) }

            // no value found
            else error "Missing argument: '%s'%s" % [param.id, expected]
          ),
        std.range(0, std.length(params) - 1),
        {}
      ),

    evalAssertionExpr(expr, env, locals):
      local expression = root.evalExpr(expr.expr, env, locals);
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
        local splitFilename = std.splitLimitR(filename, '/', 1);
        local importFilename =
          if std.startsWith(expr.path, '/')
          then expr.path
          else splitFilename[0] + '/' + expr.path;
        local parsed = parser.new(imp).parse();
        evaluator.new(importFilename, parsed, imports).eval()
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

    // FIXME: I don't understand how tailstrict works
    // ref: https://github.com/google/jsonnet/issues/343
    evalTailstrict(expr, env, locals):
      root.evalExpr(expr.expr, env + { 'tailstrict': true }, locals) tailstrict,

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
          env + {
            inBinary: false,
            'self': this,
            parentIsHidden: h == '::',
            [if isDollar then '$']: this,
          },
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
            [fieldname]+: fieldEval(this),
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
        [fieldname]::
          root.evalFunction(
            field,
            env + {
              [if isDollar then '$']: this,
            },
            locals
          ),
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
                  std.map(
                    function(newItem)
                      item + newItem,
                    root.evalForspec(spec, env, locals + item)
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
        forspec
      ),

    evalForspec(forspec, env, locals):
      std.map(
        function(i)
          { [forspec.id.id]: i },
        root.evalExpr(forspec.expr, env, locals),
      ),

    evalFieldname(fieldname, env, locals):
      if fieldname.type == 'fieldname_expr'
      then root.evalExpr(fieldname.expr, env, locals)
      else if fieldname.type == 'string'
      then root.evalString(fieldname, env, locals)
      else fieldname[fieldname.type],

    evalBinds(binds, env, locals): {
      [bind.id.id]: std.get(
        {
          bind: root.evalBind,
          bind_function: root.evalFunction,
        },
        bind.type,
        error 'Unexpected type: ' + bind.type,
      )(bind, env, locals + self)
      for bind in binds
    },

    evalBind(bind, env, locals):
      root.evalExpr(
        bind.expr,
        env,
        locals
      ),

    evalFunction(fn, env, locals):
      local params =
        std.map(
          function(param)
            {
              id: param.id.id,
              [if std.objectHas(param, 'expr') then 'default']: param.expr,
            },
          fn.params.params
        );

      function(callArgs=[], callEnv=env, callLocals=locals, evalExpr=root.evalExpr)
        local args =
          root.evalArgs(
            params,
            env,
            locals,
            callArgs,
            callEnv,
            callLocals,
            evalExpr,
          );

        root.evalExpr(fn.expr, env + callEnv, locals + args),
  },
}
