#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_LINKEDLIST_SH+true} ] && return
declare -g VARIABLES_LINKEDLIST_SH=true

. common.sh
. logger.sh
. variables.sh
. variables.atom.sh

variable::type::define LinkedList

# == LIST ==
# 
# Lists are represented as just a list of tokens to variables
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
#
function variable::LinkedList::append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    declare currentListToken="${list_token}"
    variable::value "${currentListToken}"
    declare -a node=(${RESULT})
    while [ "${#node[@]}" -eq 2 ]; do
        currentListToken="${node[1]}"
        variable::value "${currentListToken}"
        node=(${RESULT})
    done
    
    case "${#node[@]}" in
        0)
            variable::set "${currentListToken}" LinkedList "${value_token}"
            ;;
        1)
            declare -a newNode=("${value_token}")
            variable::LinkedList::new "${newNode[@]}"
            node+=("${RESULT}")
            variable::set "${currentListToken}" LinkedList "${node[*]}"
            ;;
        *)
            stderr "Unexpected list node length of ${#node[@]}"
            exit 1
            ;;
    esac
    
    RESULT=""
}

#
# Prepends a value (by token) to the beginning of a LinkedList
# Returns the token for the new beginning of the LinkedList
#
function variable::LinkedList::prepend() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::prepend ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    variable::value "${list_token}"
    declare -a node=(${RESULT})

    if [ "${#node[@]}" -eq 0 ]; then
        variable::set "${list_token}" LinkedList "${value_token}"
        RESULT="${list_token}"
    else
        declare -a node=("${value_token}" "${list_token}")
        variable::LinkedList::new "${node[*]}"
        RESULT="${RESULT}"
    fi
}

function variable::LinkedList::length() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::length ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    declare currentListToken="${list_token}"
    variable::value "${currentListToken}"
    declare -a node=(${RESULT})
    
    # empty list
    if [ "${#node[@]}" -eq 0 ]; then
        RESULT=0
        return
    fi

    declare -i count=0
    while [ "${#node[@]}" -eq 2 ]; do
        currentListToken="${node[1]}"
        variable::value "${currentListToken}"
        node=(${RESULT})
        count+=1
    done
    
    if [ "${#node[@]}" -eq 0 ]; then
        stderr "Encountered empty list at end of linked list"
        exit 1
    fi

    count+=1
    RESULT=$count
}

function variable::LinkedList::index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list::index ${@}" ; fi
    declare token="${1}"
    declare -i index="${2}"

    variable::type::instanceOfOrExit "${token}" LinkedList

    variable::value "${token}"
    if [ -z "${RESULT}" ]; then
        stderr "Invalid index [${index}]: empty list"
        exit 1
    fi

    declare -i i
    declare -a node
    for ((i=0; i<index; i=i+1)); do
        variable::value "${token}"
        if [ -z "${RESULT}" ];then
            stderr "Found empty list at end of LinkedList"
            exit 1
        fi
        node=(${RESULT})
        if [ "${#node[@]}" -eq 1 ]; then
            stderr "Index out of bounds"
            exit 1
        fi
        token="${node[1]}"
    done

    variable::value "${token}"
    if [ -z "${RESULT}" ];then
        stderr "Found empty list at end of LinkedList"
        exit 1
    fi
    node=(${RESULT})
    RESULT="${node[0]}"
}

# TODO: Commands past here are not implemented

function variable::LinkedList::first() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::first ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    variable::LinkedList::index ${list_token} 0
}

function _variable::LinkedList::first_p() {
    variable::LinkedList::first "${@}"
    echo "${RESULT}"
}

function variable::LinkedList::rest() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::rest ${@}" ; fi
    declare list_token=$1

    variable::type::instanceOfOrExit "${list_token}" LinkedList

    variable::value "${list_token}" ; declare -a values=($RESULT)
    RESULT="${values[@]:1}"
}

function _variable::LinkedList::rest_p() {
    variable::LinkedList::rest "${@}"
    echo "${RESULT}"
}

#
# Returns code 0 if the list is empty, 1 if not
#
function variable::LinkedList::isEmpty_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::LinkedList::isEmpty_c ${@}" ; fi
    declare token="${1}"

    variable::type::instanceOfOrExit "${list_token}" LinkedList

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

# length
variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::length $vCode ; \
    assert::equals 0 "${RESULT}" "length empty list"

# prepend + length
variable::new String "A" ; \
    variable::LinkedList::prepend ${vCode} ${RESULT} ; \
    vCode="${RESULT}"
variable::LinkedList::length $vCode ; \
    assert::equals 1 "${RESULT}" "prepend length 1"

variable::new String "B" ; \
    variable::LinkedList::prepend ${vCode} ${RESULT} ; \
    vCode="${RESULT}"
variable::LinkedList::length $vCode ; \
    assert::equals 2 "${RESULT}" "prepend length 2"

# prepend + index
variable::LinkedList::index $vCode 0
variable::value ${RESULT}
assert::equals "B" ${RESULT} "prepend index 0"

variable::LinkedList::index $vCode 1
variable::value ${RESULT}
assert::equals "A" ${RESULT} "prepend index 1"

# append + length
variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::length $vCode ; \
    assert::equals 0 "${RESULT}" "length empty list"

variable::new String "A" ; \
    variable::LinkedList::append ${vCode} ${RESULT}
variable::LinkedList::length $vCode ; \
    assert::equals 1 "${RESULT}" "append length 1"

variable::new String "B" ; \
    variable::LinkedList::append ${vCode} ${RESULT}
variable::LinkedList::length $vCode ; \
    assert::equals 2 "${RESULT}" "append length 2"

# append + index
variable::LinkedList::index $vCode 0
variable::value ${RESULT}
assert::equals "A" ${RESULT} "append index 0"

variable::LinkedList::index $vCode 1
variable::value ${RESULT}
assert::equals "B" ${RESULT} "append index 1"

# index empty list
variable::LinkedList::new     ; vCode=${RESULT}
ignore=$(variable::LinkedList::index $vCode 0)
assert::equals 1 $? "exit code length of empty list"

# TODO: finish the rest of this

variable::type $vCode ; \
    assert::equals LinkedList "$RESULT" "List type"
variable::LinkedList::index $vCode 0 ; variable::type "${RESULT}" ; \
    assert::equals Identifier "$RESULT" "List first item type"
variable::LinkedList::index $vCode 1 ; variable::type "${RESULT}" ; \
    assert::equals Integer "${RESULT}" "List first item type"
variable::LinkedList::index $vCode 2 ; variable::type "${RESULT}" ; \
    assert::equals Integer "${RESULT}" "List first item type"

variable::LinkedList::new     ; vCode=${RESULT}
variable::new String "a" ; A=${RESULT} ; variable::LinkedList::append ${vCode} $A
variable::new String "b" ; B=${RESULT} ; variable::LinkedList::append ${vCode} $B
variable::new String "c" ; C=${RESULT} ; variable::LinkedList::append ${vCode} $C

variable::LinkedList::index $vCode 1 ; \
    assert::equals "$B" "$RESULT" "index_p"
variable::LinkedList::first $vCode ; \
    assert::equals "$A" "$RESULT" "first_p"
variable::LinkedList::rest $vCode 0 ; \
    assert::equals "${B} ${C}" "$RESULT" "rest_p"

variable::new -name "EVAL_RESULT" Integer 4 ; declare varname="${RESULT}"

assert::equals "EVAL_RESULT" "${varname}" "Non-auto variable name"
variable::type "${varname}" ; \
    assert::equals Integer "${RESULT}" "Non-auto type"
variable::value "${varname}" ; \
    assert::equals 4 "${RESULT}" "Non-auto value"

variable::LinkedList::new     ; vCode=${RESULT}
variable::LinkedList::isEmpty_c ${vCode}
assert::equals 0 $? "Return code true (0)"
variable::new Identifier "+" ; variable::LinkedList::append ${vCode} ${RESULT}
variable::LinkedList::isEmpty_c ${vCode}
assert::equals 1 $? "Return code false (1)"

# append
variable::LinkedList::new     ; vCode=${RESULT}
variable::new Integer 5 ; variable::LinkedList::append ${vCode} ${RESULT}
variable::new Integer 2 ; variable::LinkedList::append ${vCode} ${RESULT}
variable::LinkedList::index $vCode 0 ; variable::value "${RESULT}" ; \
    assert::equals 5 "$RESULT" "append / 0"
variable::LinkedList::index $vCode 1 ; variable::value "$RESULT" ; \
    assert::equals 2 "$RESULT" "append / 1"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi
