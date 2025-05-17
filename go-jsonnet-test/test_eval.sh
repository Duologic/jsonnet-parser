#!/usr/bin/env bash
set -xeuo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

cd $DIRNAME
jb install
cd -

#    grep -v linter.golden | \                   # Don't test linter tests
#    grep -v std.makeArray_recursive.golden | \  # Times out, failing test
#    grep -v 'native.*.golden' | \               # Implementation specific (go-jsonnet native functions I assume)
#    grep -v 'extvar_.*.golden' | \              # Can succeed, needs adjustments on test scripts
#
# Succeeds with plain jsonnet, new functions in v0.21.0 that need to land in jrsonnet
#    grep -v 'builtinTrim.*.golden' | \
#
# Succeeds with plain jsonnet, bug in jrsonnet: https://github.com/CertainLach/jrsonnet/issues/194
#    grep -v std.filter7.golden | \
#
# Succeeds with plain jsonnet, bug in jrsonnet: https://github.com/CertainLach/jrsonnet/issues/190
#    grep -v foldl_single_element.golden | \
#    grep -v foldr_single_element.golden | \
#    grep -v foldl_string.golden | \
#    grep -v foldr_string.golden | \

GOLDEN=$(find ${DIRNAME}/vendor/testdata/ -name \*.golden -type f | \
    grep -v linter.golden | \
    grep -v std.filter7.golden | \
    grep -v std.makeArray_recursive.golden | \
    grep -v 'native.*.golden' | \
    grep -v 'builtinTrim.*.golden' | \
    grep -v 'extvar_.*.golden' | \
    grep -v foldl_single_element.golden | \
    grep -v foldr_single_element.golden | \
    grep -v foldl_string.golden | \
    grep -v foldr_string.golden | \
    sort)

echo "${GOLDEN}" | wc -l

echo > success.log
echo > fail.log
echo > gold.log
echo > nogold.log
echo > nogolddiff.log
for F in $GOLDEN; do
    J="${F/golden/jsonnet}"
    set +e
    jsonnet $F 2>&1 1> /dev/null
    if [[ ${?} -eq 0 ]]; then
        #set -e
        echo "eval: $J"
        EXEC=$(${DIRNAME}/../scripts/eval.sh $J) #> /dev/null
        if [[ ${?} -eq 0 ]]; then
            echo "$J" >> success.log
            GOLD=$(jrsonnet $J)
            if [ "${EXEC}" = "${GOLD}" ]; then
                echo "$J" >> gold.log
            else
                echo "$J" >> nogold.log
                set +e
                echo "$J" >> nogolddiff.log
                diff  <(echo "$EXEC" ) <(echo "$GOLD") >> nogolddiff.log
                set -e
            fi
        else
            echo "$J" >> fail.log
        fi
    fi
    set -e
done
