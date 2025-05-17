#!/usr/bin/env bash
#set -euo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

cd $DIRNAME
jb install
cd -

cd $DIRNAME/..
jb install
cd -

GOLDEN=$(find ${DIRNAME}/vendor/testdata/ -name \*.golden -type f | \
    grep -v linter | \
    grep -v std.filter7.golden | \
    grep -v 'native.*.golden' | \
    grep -v 'builtinTrim.*.golden' | \
    grep -v 'extvar_.*.golden' | \
    grep -v foldl_single_element.golden | \
    grep -v foldr_single_element.golden | \
    grep -v foldl_string.golden | \
    grep -v foldr_string.golden)

for F in $GOLDEN; do
    J=$(echo $F|sed 's/golden$/jsonnet/')
    set +e
    jsonnet $F > /dev/null 2>&1
    if [ $? == 0 ]; then
        set -e
        echo $J
        jrsonnet $J > /dev/null
    fi
    set -e
done
