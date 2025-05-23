#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

if [ "$#" != 1 ]; then
  echo "Usage: $(basename "$0") <file>"
  exit 1
fi

f=$(realpath $1)

jrsonnet -J $DIRNAME/../vendor $f
