#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

if [ "$#" != 1 ]; then
  echo "Usage: $(basename "$0") <file>"
  exit 1
fi

f=$(realpath $1)

jrsonnet --os-stack 1000 --max-stack 100000 -J $DIRNAME/../vendor -e "(import '$DIRNAME/../eval.libsonnet').new('$f', importstr '$f', import '$DIRNAME/../go-jsonnet-test-imports.libsonnet').eval()"
