#!/bin/bash

# If this file has already been sourced, just return
[ ${TESTS_TEST_SH+true} ] && return
declare -g TESTS_TEST_SH=true

declare -g -A ASSERT_RESULTS=([total]=0 [passed]=0 [failed]=0)

function assert::equals() {
    declare expect=$1
    declare actual=$2
    declare message=${@:3}
    (( ASSERT_RESULTS[total]+=1 ))
    if [ "$expect" != "$actual" ]; then
        echo "FAILED ($message)
	Expected: $expect
        Actual: $actual"
        (( ASSERT_RESULTS[failed]+=1 ))
        return 1
    fi
    echo "PASSED $message"
    (( ASSERT_RESULTS[passed]+=1 ))
    return 0
}

function assert::report() {
    echo "TESTS [total=${ASSERT_RESULTS[total]}] [passed=${ASSERT_RESULTS[passed]}] [failed=${ASSERT_RESULTS[failed]}]"
}

