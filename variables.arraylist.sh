#!/bin/bash

. common.sh
require logger
require variables
provide variables.arraylist

# == LIST ==
# 
# Lists are represented as just a list of tokens to variables
#
function variable::list::append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type "${list_token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [${$RESULT}]"
        variable::printMetadata
        exit 1
    fi

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    list_value+=(${value_token})
    VARIABLES_VALUES[$list_token]=${list_value[@]}

    RESULT=${#list_value[@]}
}

function variable::list::prepend() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::prepend ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type "${list_token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [${$RESULT}]"
        variable::printMetadata
        exit 1
    fi

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    declare -a new_value=("${value_token}" "${list_value[@]}")
    VARIABLES_VALUES[$list_token]=${new_value[@]}

    RESULT=${#list_value[@]}
}

function variable::list::length() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::length ${@}" ; fi
    declare list_token=$1

    variable::type "${list_token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [${$RESULT}]"
        variable::printMetadata
        exit 1
    fi

    variable::value "${list_token}" ; declare -a value=("${RESULT}")
    RESULT="${#value[@]}"
}

function variable::list::index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list::index ${@}" ; fi
    declare list_token=$1

    variable::type "${list_token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [${$RESULT}]"
        exit 1
    fi
    declare index=$2
    variable::value "${list_token}" ; declare -a value=(${RESULT})
    RESULT=${value[$index]}
}

function _variable::list::index_p() {
    variable::list::index "${@}"
    echo "$RESULT"
}

function variable::list::first() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::first ${@}" ; fi
    declare list_token=$1

    variable::type "${list_token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [${$RESULT}]"
        exit 1
    fi
    variable::list::index ${list_token} 0
}

function _variable::list::first_p() {
    variable::list::first "${@}"
    echo "${RESULT}"
}

function variable::list::rest() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::rest ${@}" ; fi
    declare list_token=$1

    variable::type "${list_token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [${$RESULT}]"
        exit 1
    fi

    variable::value "${list_token}" ; declare -a values=($RESULT)
    RESULT="${values[@]:1}"
}

function _variable::list::rest_p() {
    variable::list::rest "${@}"
    echo "${RESULT}"
}

#
# Returns code 0 if the list is empty, 1 if not
#
function variable::list::isEmpty_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::isEmpty_c ${@}" ; fi
    declare token="${1}"

    variable::type "${token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot append to variable [${token}] of type [${$RESULT}]"
        exit 1
    fi

    variable::value "${token}" ; declare -a value=(${RESULT})
    [[ ${#value[@]} -eq 0 ]]
    return $?
}


# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

# == LIST TESTS ==
# create a new list
# test its size is 0
# add an atom to list
# test its size is 1
# retrieve value of first item (atom) in list

variable::new list           ; vCode=${RESULT}
variable::new identifier "+" ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5      ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2      ; variable::list::append ${vCode} ${RESULT}

variable::type $vCode ; \
    assert::equals list "$RESULT" "List type"
variable::list::index $vCode 0 ; variable::type "${RESULT}" ; \
    assert::equals identifier "$RESULT" "List first item type"
variable::list::index $vCode 1 ; variable::type "${RESULT}" ; \
    assert::equals integer "${RESULT}" "List first item type"
variable::list::index $vCode 2 ; variable::type "${RESULT}" ; \
    assert::equals integer "${RESULT}" "List first item type"

variable::new list ; vCode=${RESULT}
variable::new string "a" ; A=${RESULT} ; variable::list::append ${vCode} $A
variable::new string "b" ; B=${RESULT} ; variable::list::append ${vCode} $B
variable::new string "c" ; C=${RESULT} ; variable::list::append ${vCode} $C

variable::list::index $vCode 1 ; \
    assert::equals "$B" "$RESULT" "index_p"
variable::list::first $vCode ; \
    assert::equals "$A" "$RESULT" "first_p"
variable::list::rest $vCode 0 ; \
    assert::equals "${B} ${C}" "$RESULT" "rest_p"

variable::new -name "EVAL_RESULT" integer 4 ; declare varname="${RESULT}"

assert::equals "EVAL_RESULT" "${varname}" "Non-auto variable name"
variable::type "${varname}" ; \
    assert::equals integer "${RESULT}" "Non-auto type"
variable::value "${varname}" ; \
    assert::equals 4 "${RESULT}" "Non-auto value"

variable::new list ; vCode=${RESULT}
variable::list::isEmpty_c ${vCode}
assert::equals 0 $? "Return code true (0)"
variable::new identifier "+" ; variable::list::append ${vCode} ${RESULT}
variable::list::isEmpty_c ${vCode}
assert::equals 1 $? "Return code false (1)"

# append
variable::new list ; vCode=${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
variable::list::index $vCode 0 ; variable::value "${RESULT}" ; \
    assert::equals 5 "$RESULT" "append / 0"
variable::list::index $vCode 1 ; variable::value "$RESULT" ; \
    assert::equals 2 "$RESULT" "append / 1"

assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi



