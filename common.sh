
. logger.sh

function stderr() {
    echo "${@}" 2>&1
}

if [ -z "${ASSERT_RESULTS}" ]; then
    declare -A ASSERT_RESULTS=([total]=0 [passed]=0 [failed]=0)
fi

function assert::equals() {
    declare expect=$1
    declare actual=$2
    declare message=${@:3}
    (( ASSERT_RESULTS[total]+=1 ))
    if [ "$expect" != "$actual" ]; then
        echo "FAILED ('$expect' != '$actual') $message"
        log "FAILED ('$expect' != '$actual') $message"
        (( ASSERT_RESULTS[failed]+=1 ))
        return 1
    fi
    echo "PASSED $message"
    log "PASSED $message"
    (( ASSERT_RESULTS[passed]+=1 ))
    return 0
}

function assert::report() {
    echo "TESTS [total=${ASSERT_RESULTS[total]}] [passed=${ASSERT_RESULTS[passed]}] [failed=${ASSERT_RESULTS[failed]}]"
}
