#!/usr/bin/env bash
set -xeuo pipefail
IFS=$'\n\t'

DIRNAME="$(dirname "$0")"

cd $DIRNAME
jb install
cd -

GOLDEN=$(find ${DIRNAME}/vendor/testdata/ -name \*.golden -type f | \
    grep -v linter | \
    grep -v tailstrict | \
    grep -v std.filter7.golden | \
    grep -v std.makeArray_recursive.golden | \
    grep -v object_invariant_perf.golden | \
    grep -v 'native.*.golden' | \
    grep -v 'builtinTrim.*.golden' | \
    grep -v 'extvar_.*.golden' | \
    grep -v foldl_single_element.golden | \
    grep -v foldr_single_element.golden | \
    grep -v foldl_string.golden | \
    grep -v foldr_string.golden | sort)

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
            GOLD=$(cat $F)
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
