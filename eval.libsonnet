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
        trace: {
          params: [
            { id: 'str' },
            { id: 'rest' },
          ],
          call(args):
            std.trace(args.str, args.rest),
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
          array: root.evalArray,
          fieldaccess: root.evalFieldaccess,
          functioncall: root.evalFunctioncall,
          id: root.evalIdentifier,
          local_bind: root.evalLocalBind,
          binary: root.evalBinary,
          unary: root.evalUnary,
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
      local objectLocals =
        std.filter(
          function(member)
            member.type == 'object_local',
          expr.members
        );
      local localEnv = {
        [objectLocal.bind.id.id]: root.evalExpr(objectLocal.bind.expr, env + self)
        for objectLocal in objectLocals
      };

      local fieldFunctions =
        std.filter(
          function(member)
            member.type == 'field_function',
          expr.members
        );
      local fieldFunctionsEval =
        std.foldr(
          function(field, acc)
            acc + root.evalObjectFieldFunction(field, env),
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
            acc + root.evalObjectField(field, fieldsEnv + { 'self'+: acc }),
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

    evalArray(expr, env):
      std.map(function(item) root.evalExpr(item, env), expr.items),

    evalObjectField(field, env):
      local fieldname = root.evalObjectFieldname(field.fieldname, env);
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

    evalObjectFieldFunction(field, env):
      local fieldname = root.evalObjectFieldname(field.fieldname, env);
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
                [if std.objectHas(param, 'expr') then 'default']: root.evalExpr(param.expr),
              },
            field.params.params
          ),
          call(args):
            root.evalExpr(field.expr, env + args),
        },
      },

    evalObjectFieldname(fieldname, env):
      if fieldname.type == 'fieldname_expr'
      then root.evalExpr(fieldname.expr, env)
      else fieldname[fieldname.type],

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

    evalLocalBind(expr, env):
      local newenv = env + { [expr.bind.id.id]: root.evalExpr(expr.bind.expr, env) };
      root.evalExpr(expr.expr, newenv),

    evalBinary(expr, env):
      local leftEval = root.evalExpr(expr.left_expr, env);
      local rightEval = root.evalExpr(expr.right_expr, env);
      std.get(
        {
          '+': leftEval + rightEval,
          '/': leftEval / rightEval,
          '&&': leftEval && rightEval,
          '||': leftEval || rightEval,
          '==': leftEval == rightEval,
        },
        expr.binaryop,
        error 'Unexpected operator: ' + expr.binaryop
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
