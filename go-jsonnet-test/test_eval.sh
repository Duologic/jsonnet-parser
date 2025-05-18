#!/usr/bin/env bash
set -xeuo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

cd $DIRNAME
jb install
cd -

cd $DIRNAME/..
jb install
cd -


#    grep -v linter.golden | \                   # Don't test linter tests
#    grep -v std.makeArray_recursive.golden | \  # Times out, failing test
#    grep -v 'native.*.golden' | \               # Can succeed, needs adjustments on test scripts
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
#
# Succeeds with plain jsonnet, bug in jrsonnet: https://github.com/CertainLach/jrsonnet/issues/195
#    grep -v insuper5.golden | \


GOLDEN=$(find ${DIRNAME}/vendor/github.com/google/go-jsonnet/testdata/ -name \*.golden -type f | \
    grep -v linter.golden | \
    grep -v insuper5.golden | \
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

rm -rf "${DIRNAME}"/success.log
rm -rf "${DIRNAME}"/fail.log
rm -rf "${DIRNAME}"/gold.log
rm -rf "${DIRNAME}"/nogold.log

for F in $GOLDEN; do
    J="${F/golden/jsonnet}"
    set +e
    jsonnet $F 2>&1 1> /dev/null
    if [[ ${?} -eq 0 ]]; then
        #set -e
        echo "eval: $J"
        EXEC=$(${DIRNAME}/../scripts/eval.sh $J) #> /dev/null
        if [[ ${?} -eq 0 ]]; then
            echo "$J" >> "${DIRNAME}"/success.log
            GOLD=$(jrsonnet $J)
            if [ "${EXEC}" = "${GOLD}" ]; then
                echo "$J" >> "${DIRNAME}"/gold.log
            else
                echo "$J" >> "${DIRNAME}"/nogold.log
            fi
        else
            echo "$J" >> "${DIRNAME}"/fail.log
        fi
    fi
    set -e
done

[ -f "${DIRNAME}"/fail.log ] && cat "${DIRNAME}"/fail.log && exit 1
exit 0
