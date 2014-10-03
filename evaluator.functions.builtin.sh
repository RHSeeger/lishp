#!/bin/bash

# If this file has already been sourced, just return
[ ${EVALUATOR__FUNCTIONS_BUILTIN_SH+true} ] && return
declare -g EVALUATOR__FUNCTIONS_BUILTIN_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/environment.sh

function evaluator::functions::builtin::add() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::add ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare result="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${env}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        (( result += ${currentValue} ))
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Integer "${result}"
    RESULT="${RESULT}"
}

function evaluator::functions::builtin::subtract() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::subtract ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare result="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        (( result -= "${currentValue}" ))
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Integer "${result}"
    RESULT="${RESULT}"
}

function evaluator::functions::builtin::multiply() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::multiply ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare result="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        (( result *= "${currentValue}" ))
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Integer "${result}"
    RESULT="${RESULT}"
}

function evaluator::functions::builtin::divide() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::divide ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare result="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        (( result /= "${currentValue}" ))
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Integer "${result}"
    RESULT="${RESULT}"
}

function evaluator::functions::builtin::equals() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::equals ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare first="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        if [[ $first -ne $currentValue ]]; then
            variable::new Boolean false
            RESULT="${RESULT}"
            return
        fi
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Boolean true
    RESULT="${RESULT}"
    return
}

function evaluator::functions::builtin::greaterthan() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::equals ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare first="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        if [[ ! $first -gt $currentValue ]]; then
            variable::new Boolean false
            RESULT="${RESULT}"
            return
        fi
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Boolean true
    RESULT="${RESULT}"
    return
}

function evaluator::functions::builtin::lessthan() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::equals ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare first="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        if [[ ! $first -lt $currentValue ]]; then
            variable::new Boolean false
            RESULT="${RESULT}"
            return
        fi
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Boolean true
    RESULT="${RESULT}"
    return
}

function evaluator::functions::builtin::greaterthanorequal() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::equals ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare first="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        if [[ ! $first -ge $currentValue ]]; then
            variable::new Boolean false
            RESULT="${RESULT}"
            return
        fi
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Boolean true
    RESULT="${RESULT}"
    return
}

function evaluator::functions::builtin::lessthanorequal() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::functions::builtin::equals ${@}" ; fi

    declare env="${1}"
    declare functionName="${2}"
    declare argsToken="${3}"

    variable::LinkedList::length "${argsToken}"
    if [[ $RESULT < 2 ]]; then
        stderr "add not valid with less than 2 arguments"
        exit 1
    fi

    variable::LinkedList::first "${argsToken}" ; declare headToken="${RESULT}"
    evaluator::eval "${env}" "${RESULT}"
    variable::value "${RESULT}" ; declare first="${RESULT}"
    variable::LinkedList::rest "${argsToken}" ; declare rest="${RESULT}"
    declare currentToken
    declare currentValue

    while ! variable::LinkedList::isEmpty_c "${rest}"; do
        variable::LinkedList::first "${rest}"
        evaluator::eval "${envToken}" "${RESULT}"
        currentToken="${RESULT}"
        if ! variable::type::instanceOf "${currentToken}" Integer; then
            variable::type ${currentToken}
            stderr "Cannot add type [${RESULT}]"
            exit 1
        fi
        variable::value "${currentToken}" ; currentValue="${RESULT}"
        if [[ ! $first -le $currentValue ]]; then
            variable::new Boolean false
            RESULT="${RESULT}"
            return
        fi
        variable::LinkedList::rest "${rest}"; rest="${RESULT}"
    done

    variable::new Boolean true
    RESULT="${RESULT}"
    return
}
