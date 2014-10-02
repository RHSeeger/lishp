#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_ARRAYLIST_SH+true} ] && return
declare -g VARIABLES_ARRAYLIST_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/logger.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.atom.sh

variable::type::define ArrayList

# == LIST ==
# 
# Lists are represented as just a list of tokens to variables
#

function variable::ArrayList::new() {
    variable::new ArrayList "${@}"
}

function variable::ArrayList::append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type::instanceOfOrExit "${list_token}" ArrayList

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    list_value+=(${value_token})
    VARIABLES_VALUES[$list_token]=${list_value[@]}

    RESULT=${#list_value[@]}
}

function variable::ArrayList::prepend() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::prepend ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type::instanceOfOrExit "${list_token}" ArrayList

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    declare -a new_value=("${value_token}" "${list_value[@]:+${list_value[@]}}")
    VARIABLES_VALUES[$list_token]=${new_value[@]}

    RESULT=${#list_value[@]}
}

function variable::ArrayList::length() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::length ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" ArrayList

    variable::value "${list_token}" ; declare -a value=("${RESULT}")
    RESULT="${#value[@]}"
}

function variable::ArrayList::index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list::index ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" ArrayList

    declare index=$2
    variable::value "${list_token}" ; declare -a value=(${RESULT})
    RESULT=${value[$index]}
}

function _variable::ArrayList::index_p() {
    variable::ArrayList::index "${@}"
    echo "$RESULT"
}

function variable::ArrayList::first() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::first ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" ArrayList

    variable::ArrayList::index ${list_token} 0
}

function _variable::ArrayList::first_p() {
    variable::ArrayList::first "${@}"
    echo "${RESULT}"
}

function variable::ArrayList::rest() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::rest ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" ArrayList

    variable::value "${list_token}" ; declare -a values=($RESULT)
    RESULT="${values[@]:1}"
}

function _variable::ArrayList::rest_p() {
    variable::ArrayList::rest "${@}"
    echo "${RESULT}"
}

#
# Returns code 0 if the list is empty, 1 if not
#
function variable::ArrayList::isEmpty_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::isEmpty_c ${@}" ; fi
    declare token="${1}"

    variable::type::instanceOfOrExit "${token}" ArrayList

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

variable::ArrayList::new     ; vCode=${RESULT}
variable::new Identifier "+" ; variable::ArrayList::append ${vCode} ${RESULT}
variable::new Integer 5      ; variable::ArrayList::append ${vCode} ${RESULT}
variable::new Integer 2      ; variable::ArrayList::append ${vCode} ${RESULT}

variable::type $vCode ; \
    assert::equals ArrayList "$RESULT" "List type"
variable::ArrayList::index $vCode 0 ; variable::type "${RESULT}" ; \
    assert::equals Identifier "$RESULT" "List first item type"
variable::ArrayList::index $vCode 1 ; variable::type "${RESULT}" ; \
    assert::equals Integer "${RESULT}" "List first item type"
variable::ArrayList::index $vCode 2 ; variable::type "${RESULT}" ; \
    assert::equals Integer "${RESULT}" "List first item type"

variable::ArrayList::new     ; vCode=${RESULT}
variable::new String "a" ; A=${RESULT} ; variable::ArrayList::append ${vCode} $A
variable::new String "b" ; B=${RESULT} ; variable::ArrayList::append ${vCode} $B
variable::new String "c" ; C=${RESULT} ; variable::ArrayList::append ${vCode} $C

variable::ArrayList::index $vCode 1 ; \
    assert::equals "$B" "$RESULT" "index_p"
variable::ArrayList::first $vCode ; \
    assert::equals "$A" "$RESULT" "first_p"
variable::ArrayList::rest $vCode 0 ; \
    assert::equals "${B} ${C}" "$RESULT" "rest_p"

variable::new -name "EVAL_RESULT" Integer 4 ; declare varname="${RESULT}"

assert::equals "EVAL_RESULT" "${varname}" "Non-auto variable name"
variable::type "${varname}" ; \
    assert::equals Integer "${RESULT}" "Non-auto type"
variable::value "${varname}" ; \
    assert::equals 4 "${RESULT}" "Non-auto value"

variable::ArrayList::new     ; vCode=${RESULT}
variable::ArrayList::isEmpty_c ${vCode}
assert::equals 0 $? "Return code true (0)"
variable::new Identifier "+" ; variable::ArrayList::append ${vCode} ${RESULT}
variable::ArrayList::isEmpty_c ${vCode}
assert::equals 1 $? "Return code false (1)"

# append
variable::ArrayList::new     ; vCode=${RESULT}
variable::new Integer 5 ; variable::ArrayList::append ${vCode} ${RESULT}
variable::new Integer 2 ; variable::ArrayList::append ${vCode} ${RESULT}
variable::ArrayList::index $vCode 0 ; variable::value "${RESULT}" ; \
    assert::equals 5 "$RESULT" "append / 0"
variable::ArrayList::index $vCode 1 ; variable::value "$RESULT" ; \
    assert::equals 2 "$RESULT" "append / 1"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi
