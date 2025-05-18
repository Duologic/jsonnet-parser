# jsonnet implementation in jsonnet

This is a parser and interpreter for Jsonnet written in Jsonnet. It serves as a research project to get a better understanding how a parser and interpreter works.

I'm running this with the rust version `jrsonnet` as the go version is orders of magnitude slower. Also see examples in `Makefile` and `scripts/` for setting `--max-stack` and `--os-stack`.

## parser

The output format of the parser is a JSON object that matches a schema from [ASTsonnet](https://github.com/crdsonnet/astsonnet) to generate the Jsonnet code again.

## interpreter

`eval.libsonnet` can be used to evaluate jsonnet from within jsonnet, it can be called with `./scripts/eval.sh <file>` on the command line, which will resolve the imports for you.
