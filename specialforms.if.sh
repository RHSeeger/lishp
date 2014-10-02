#!/bin/bash

# If this file has already been sourced, just return
[ ${SPECIALFORMS_IF_SH+true} ] && return
declare -g SPECIALFORMS_IF_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/test.sh
. ${BASH_SOURCE%/*}/specialforms.sh

#
# IF
#
# Predicate, consequent, and alternative are expressions. An if expression is
# evaluated as follows: first, predicate is evaluated. If it yields a true
# value, then consequent is evaluated and its value is returned. Otherwise
# alternative is evaluated and its value is returned. If predicate yields a
# false value and no alternative is specified, then the result of the expression
# is unspecified.
#
# An if expression evaluates either consequent or alternative, never
# both. Programs should not depend on the value of an if expression that has no
# alternative.
#
# (if (> 3 2) 'yes 'no)                   =>  yes
# (if (> 2 3) 'yes 'no)                   =>  no
# (if (> 3 2)
#     (- 3 2)
#     (+ 3 2))                            =>  1
#
function evaluator::specialforms::if() {
    declare env="${1}"
    declare functionName="${2}" # if
    declare args="${3}" # list of condition, <true branch>, <false branch>

    variable::LinkedList::length $args ; declare -i length="${RESULT}"
    if [[ $length != 3 ]]; then
        stderr "usage: (if condition true-branch false-branch)"
        exit 1
    fi

    variable::LinkedList::index $args 0 ; declare condition=${RESULT}
    variable::LinkedList::index $args 1 ; declare trueBranch=${RESULT}
    variable::LinkedList::index $args 2 ; declare falseBranch=${RESULT}

    evaluator::eval $env $condition ; declare conditionResult=${RESULT}
    variable::type::instanceOfOrExit $conditionResult Boolean

    variable::value $conditionResult
    if [[ "true" == "${RESULT}" ]]; then
        evaluator::eval $env $trueBranch
    else
        evaluator::eval $env $falseBranch
    fi
    RESULT="${RESULT}"
}



# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

#
# TRUE
#
#
# not using env
#
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "if"

variable::LinkedList::new ; conditional="${RESULT}"
appendToList $conditional Identifier "=" Integer 3 Integer 3
variable::LinkedList::append $command $conditional

appendToList $command String yes String no

evaluator::eval $env $command
variable::debug "${RESULT}" ; \
    assert::equals "String :: yes" "${RESULT}" "(if (= 3 3) 'yes 'no)"


#
# FALSE
# 
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "if"

variable::LinkedList::new ; conditional="${RESULT}"
appendToList $conditional Identifier "=" Integer 3 Integer 4
variable::LinkedList::append $command $conditional

appendToList $command String yes String no

evaluator::eval $env $command
variable::debug "${RESULT}" ; \
    assert::equals "String :: no" "${RESULT}" "(if (= 3 4) 'yes 'no)"


#
# Evaluates result
#
createTestEnv ; env="${RESULT}"
setInEnv $env "v" Integer 10
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "if"

variable::LinkedList::new ; conditional="${RESULT}"
appendToList $conditional Identifier "=" Integer 3 Integer 4
variable::LinkedList::append $command $conditional

appendToList $command Integer 5 Identifier v

evaluator::eval $env $command
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 10" "${RESULT}" "(if (= 3 4) 'yes 'no)"



assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

