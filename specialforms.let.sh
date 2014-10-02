#!/bin/bash

# If this file has already been sourced, just return
[ ${SPECIALFORMS_LET_SH+true} ] && return
declare -g SPECIALFORMS_LET_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/test.sh
. ${BASH_SOURCE%/*}/specialforms.sh

#
# LET
# 
# The inits are evaluated in the current environment (in some unspecified order), 
# the variables are bound to fresh locations holding the results, the expressions
# are evaluated sequentially in the extended environment, and the value of the
# last expression is returned. Each binding of a variable has the expressions as
# its region. 
#
# (let ((x 2) (y 3))
#      (* x y))     
#

function evaluator::specialforms::let() {
    declare env="${1}"
    declare functionName="${2}" # let
    declare args="${3}" # list of <formal args list>, <expression>,...,<expression>

    variable::LinkedList::length $args ; declare -i length="${RESULT}"
    if [[ $length < 2 ]]; then
        stderr "usage: (let <bindings> <expr 1> .. <expr N>)"
        exit 1
    fi

    variable::LinkedList::first $args ; declare bindings=${RESULT}
    variable::LinkedList::rest $args ; declare expressions=${RESULT}

    # set values
    environment::pushScope $env ; declare runningEnv="${RESULT}"
    declare thisKeyToken
    declare thisValueToken
    # while ! variable::LinkedList::isEmpty_c "${bindings}" ; do
    #     ... blah
    # done

    # evaluate expressions
    declare currentSexp currentResult
    while ! variable::LinkedList::isEmpty_c "${expressions}" ; do
        variable::LinkedList::first "${expressions}" ; currentSexp=${RESULT}
        variable::LinkedList::rest "${expressions}" ; expressions=${RESULT}
        evaluator::eval $runningEnv $currentSexp
        currentResult=${RESULT}
    done
    RESULT="${currentResult}"
}



# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi





assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

