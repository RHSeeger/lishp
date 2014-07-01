
function stderr() {
    echo "${@}" 2>&1
}

function assertEquals() {
    declare expect=$1
    declare actual=$2
    declare message=${@:3}
    if [ "$expect" != "$actual" ]; then
        echo "FAILED ('$expect' != '$actual') $message"
        return 1
    fi
    echo "PASSED $message"
    return 0
}

