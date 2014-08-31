
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
#set -e          ;# exit if any command has a non-zero exit status
set -u          ;# a reference to any variable you haven't previously defined - with the exceptions of $* and $@ - is an error, and causes the program to immediately exit
#set -o pipefail ;# If any command in a pipeline fails, that return code will be used as the return code of the whole pipeline
#IFS=$'\n\t'

# If this file has already been sourced, just return
[ ${COMMON_SH+true} ] && return
declare -g COMMON_SH=true

# echo "Defining common commands"

function stderr() {
    echo "${@}" 2>&1
}

function functionExists() {
    declare functionName="${1}"

    declare type=$(type -t "${functionName}")
    if [[ $? != 0 ]]; then
        # not found at all
        return 1
    elif [[ $type == "function" ]]; then
        return 0
    else
        return 1
    fi
}

declare -g -A ASSERT_RESULTS=([total]=0 [passed]=0 [failed]=0)

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
    (( ASSERT_RESULTS[passed]+=1 ))
    return 0
}

function assert::report() {
    echo "TESTS [total=${ASSERT_RESULTS[total]}] [passed=${ASSERT_RESULTS[passed]}] [failed=${ASSERT_RESULTS[failed]}]"
}

