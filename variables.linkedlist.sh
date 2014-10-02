#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_LINKEDLIST_SH+true} ] && return
declare -g VARIABLES_LINKEDLIST_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/logger.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.atom.sh

variable::type::define LinkedList

# == LIST ==
# 
# LinkedLists are represented as cons pairs, lists of 2 elements
# The end of the list is represented by a Nil object
# (item_1 child_1) 
#    |      |
#    value token -> 42
#          (item_2 child_2)
#           |      |
#           value token -> 53
#                  |
#                  Nil
# Or, for an empty list, just the nil object (an empty string)
#
# There should never be a case where a LinkedList single node is a list of 1 item
#

#
# Creates a new, empty LinkedList
# Returns the token for the new list
#
function variable::LinkedList::new() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::new ${@}" ; fi
    variable::new LinkedList "${@}"
}

#
# Appends a value (by token) to the end of a LinkedList
# Returns nothing
# Does change the value of the list pointed to by the token passed in
#
function variable::LinkedList::append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    declare currToken="${list_token}"
    declare node
    declare -a nodeArr

    while true; do
        variable::value "${currToken}"
        node="${RESULT}"
        if [ "${node}" == "" ]; then # at the last node, modify here
            variable::LinkedList::new
            nodeArr=("${value_token}" "${RESULT}")
            variable::set "${currToken}" LinkedList "${nodeArr[*]}"
            RESULT=""
            return 0
        fi
        nodeArr=($node)
        if [ "${#nodeArr[@]}" -ne 2 ]; then
            stderr "Encountered node with single element at [${currToken}]=[${nodeArr[@]}]"
            exit 1
        fi
        currToken="${nodeArr[1]}"
    done

    stderr "Should never get here"
    exit 1
}

#
# Prepends a value (by token) to the beginning of a LinkedList
# Returns the token for the new beginning of the LinkedList
# Should never change the value of the list pointed to by the token passed in
#
function variable::LinkedList::prepend() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::prepend ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    variable::value "${list_token}"
    declare -a node=(${RESULT})

    declare -a node=("${value_token}" "${list_token}")
    variable::LinkedList::new "${node[*]}"
    RESULT="${RESULT}"
}

function variable::LinkedList::length() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::length ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    declare currToken="${list_token}"
    declare node
    declare -a nodeArr
    declare -i count=0

    while true; do
        variable::value "${currToken}"
        node="${RESULT}"
        if [ "${node}" == "" ]; then 
            RESULT=${count}
            return 0
        fi
        nodeArr=($node)
        if [ "${#nodeArr[@]}" -ne 2 ]; then
            stderr "Encountered node with single element at [${currToken}]=[${nodeArr[@]}]"
            exit 1
        fi
        count+=1
        currToken="${nodeArr[1]}"
    done

    stderr "Should never get here"
    exit 1
}

function variable::LinkedList::index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list::index ${@}" ; fi
    declare token="${1}"
    declare -i index="${2}"

    variable::type::instanceOfOrExit "${token}" LinkedList

    declare currToken="${token}"
    declare node
    declare -a nodeArr
    declare -i count=0

    while true; do
        variable::value "${currToken}"
        node="${RESULT}"
        if [ "${node}" == "" ]; then 
            stderr "Invalid index [${index}] for list of length [${count}]"
            exit 1
        fi
        nodeArr=($node)
        if [ "${#nodeArr[@]}" -ne 2 ]; then
            stderr "Encountered node with single element at [${currToken}]=[${nodeArr[@]}]"
            exit 1
        fi
        if [ $count -eq $index ]; then # this is the node we're looking for
            RESULT="${nodeArr[0]}"
            return 0
        fi

        count+=1
        currToken="${nodeArr[1]}"
    done

    stderr "Should never get here"
    exit 1
}

# TODO: Commands past here are not implemented

function variable::LinkedList::first() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::first ${@}" ; fi
    declare token=$1

    variable::type::instanceOfOrExit "${token}" LinkedList

    variable::LinkedList::index ${token} 0
}

function variable::LinkedList::rest() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::rest ${@}" ; fi
    declare token=$1

    variable::type::instanceOfOrExit "${token}" LinkedList

    variable::value "${token}"
    declare node="${RESULT}"
    if [ "${node}" == "" ]; then
        stderr "Called [rest] on empty list"
        exit 1
    fi

    declare -a nodeArr=($RESULT)
    RESULT="${nodeArr[1]}"
}

#
# Returns code 0 if the list is empty, 1 if not
#
function variable::LinkedList::isEmpty_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::isEmpty_c ${@}" ; fi
    declare token="${1}"

    variable::type::instanceOfOrExit "${token}" LinkedList

    variable::value "${token}"
    declare node="${RESULT}"
    if [ "${node}" == "" ]; then
        return 0
    else
        return 1
    fi
}

function variable::LinkedList::toSexp() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::toSexp ${@}" ; fi
    declare token="${1}"

    variable::type::instanceOfOrExit "${token}" LinkedList

    declare currToken="${token}"
    declare node
    declare -a nodeArr
    declare -a output=()

    while true; do
        variable::value "${currToken}"
        node="${RESULT}"
        if [ "${node}" == "" ]; then 
            if [[ ${#output[@]} == 0 ]]; then
                RESULT="()"
            else
                RESULT="(${output[@]})"
            fi
            return 0
        fi
        nodeArr=($node)
        if [ "${#nodeArr[@]}" -ne 2 ]; then
            stderr "Encountered node with single element at [${currToken}]=[${nodeArr[@]}]"
            exit 1
        fi
        variable::toSexp ${nodeArr[0]}
        output+=("${RESULT}")
        currToken="${nodeArr[1]}"
    done
    
    stderr "should never get here" ; exit 1
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

variable::new String "A" ; var_A="${RESULT}"
variable::new String "B" ; var_B="${RESULT}"
variable::new String "C" ; var_C="${RESULT}"
variable::new String "D" ; var_D="${RESULT}"

## LENGTH
# length
variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::length $vCode ; \
    assert::equals 0 "${RESULT}" "length empty list"

variable::LinkedList::prepend ${vCode} ${var_A} ; vCode_1="${RESULT}"
variable::LinkedList::length ${vCode_1} ; \
    assert::equals 1 "${RESULT}" "length after adding 1"
variable::LinkedList::length ${vCode} ; \
    assert::equals 0 "${RESULT}" "length after adding 1 - original list"

variable::LinkedList::prepend ${vCode_1} ${var_B} ; vCode_2="${RESULT}"
variable::LinkedList::length ${vCode_2} ; \
    assert::equals 2 "${RESULT}" "length after adding 2"
variable::LinkedList::length ${vCode_1} ; \
    assert::equals 1 "${RESULT}" "length after adding 2 - middle list"
variable::LinkedList::length ${vCode} ; \
    assert::equals 0 "${RESULT}" "length after adding 1 - original list"


# prepend
variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::prepend ${vCode} ${var_A} ; vCode="${RESULT}"
variable::LinkedList::prepend ${vCode} ${var_B} ; vCode="${RESULT}"
variable::LinkedList::length $vCode ; \
    assert::equals 2 "${RESULT}" "prepend length 2"
variable::LinkedList::index $vCode 0 ; \
    variable::value "${RESULT}" ; \
    assert::equals "B" "${RESULT}" "first item of prepend list"
variable::LinkedList::index $vCode 1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "A" "${RESULT}" "second item of prepend list"

# append
variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::append ${vCode} ${var_A}
variable::LinkedList::append ${vCode} ${var_B}
variable::LinkedList::length $vCode ; \
    assert::equals 2 "${RESULT}" "append length 2"
variable::LinkedList::index $vCode 0 ; \
    variable::value "${RESULT}" ; \
    assert::equals "A" "${RESULT}" "first item of append list"
variable::LinkedList::index $vCode 1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "B" "${RESULT}" "second item of append list"

# index empty list
variable::LinkedList::new     ; vCode=${RESULT}
ignore=$(variable::LinkedList::index $vCode 0)
assert::equals 1 $? "exit code length of empty list"

# Type name
variable::LinkedList::new     ; vCode=${RESULT}
variable::type $vCode ; \
    assert::equals LinkedList "$RESULT" "List type"
variable::type::instanceOf $vCode LinkedList ; \
    assert::equals 0 $? "instanceOf"

# isEmpty_c
variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::isEmpty_c ${vCode}
assert::equals 0 $? "Return code true (0)"

variable::LinkedList::append ${vCode} ${var_A}
variable::LinkedList::isEmpty_c ${vCode}
assert::equals 1 $? "Return code false (1)"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi
