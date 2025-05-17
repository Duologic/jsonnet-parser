#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

if [ "$#" != 1 ]; then
  echo "Usage: $(basename "$0") <file>"
  exit 1
fi

f=$(realpath $1)

fr=$(realpath --relative-to=$PWD $1)

JSONNET_BIN=${JSONNET_BIN:=jrsonnet}

if [ $JSONNET_BIN = 'jrsonnet' ]; then
  jrsonnet \
      --os-stack 10000 \
      --max-stack 1000000 \
      --trace-format explaining \
      -J $DIRNAME/../vendor \
      -e "(import '$DIRNAME/../eval.libsonnet').new('$fr', importstr '$f', import '$DIRNAME/../go-jsonnet-test/imports.libsonnet', {codeVar: 6}).eval()"
elif [ $JSONNET_BIN = 'jsonnet' ]; then
  # slower but more correct
  jsonnet \
      --max-stack 1000000 \
      -J $DIRNAME/../vendor \
      -e "(import '$DIRNAME/../eval.libsonnet').new('$fr', importstr '$f', import '$DIRNAME/../go-jsonnet-test/imports.libsonnet', {codeVar: 6}).eval()"
fi
