#!/usr/bin/env bash
set -euo pipefail
DIRNAME="$(dirname "$0")"

jsonnet-deps $1 | jsonnet -S -A pwd=$PWD "${DIRNAME}"/imports.jsonnet | jsonnetfmt -
