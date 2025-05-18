#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

if [ "$#" != 1 ]; then
  echo "Usage: $(basename "$0") <FILE>"
  exit 1
fi

FILE=$(realpath --relative-to=$PWD $1)

IMPORTS=$("${DIRNAME}"/imports.sh "${FILE}")
JSONNET_BIN=${JSONNET_BIN:=jrsonnet}

if [ $JSONNET_BIN = 'jrsonnet' ]; then
  jrsonnet \
      --os-stack 10000 \
      --max-stack 1000000 \
      --trace-format explaining \
      -J $DIRNAME/../vendor \
      -e "(import '$DIRNAME/../eval.libsonnet').new('${FILE}', importstr '${FILE}', ${IMPORTS}, {codeVar: 6}).eval()"
elif [ $JSONNET_BIN = 'jsonnet' ]; then
  # slower but more correct
  jsonnet \
      --max-stack 1000000 \
      -J $DIRNAME/../vendor \
      -e "(import '$DIRNAME/../eval.libsonnet').new('${FILE}', importstr '${FILE}', ${IMPORTS}, {codeVar: 6}).eval()"
fi
