#!/bin/bash

. common.sh
require logger
require variables
provide variables.stack

# == STACK ==
# 
# Last In / First Out
#
# Stack commands act on a list data structure
#

#
# Adds an item to the stack
#
function variable::stack::push() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::stack::push ${@}" ; fi
    variable::list::prepend "${@}"
}

#
# Removes and returns the most recent item added to the stack
#
function variable::stack::pop() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::stack::pop ${@}" ; fi
    declare token="${1}"

    variable::type "${token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot use [variable::stack::pop] on type [${$RESULT}]"
        exit 1
    fi
    if variable::list::isEmpty_c "${token}" ; then
        stderr "Cannot pop from an empty stack"
        exit 1
    fi

    variable::queue::peek "${token}" ; declare result=$RESULT
    variable::type $token ; declare type=$RESULT
    variable::list::rest $token ; declare value=$RESULT
    variable::set "$token" "$type" "$value"
    RESULT="${result}"
}

#
# Returns the most recent item added to the stack (does note remove it)
#
function variable::stack::peek() {
    declare token="${1}"
    variable::type "${token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot use [variable::stack::peek] on type [${$RESULT}]"
        exit 1
    fi
    if variable::list::isEmpty_c $token ; then
        stderr "Cannot peek from an empty stack"
        exit 1
    fi

variable::list::first $token ;    declare result=$RESULT
    RESULT="${result}"
}
function _variable::stack::peek_p() {
    variable::stack::peek "${@}"
    echo "$RESULT"
}

# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi


#
# STACK tests
#
variable::new list ; vCode=${RESULT}
variable::new string "first" ; variable::stack::push ${vCode} ${RESULT}
variable::new string "second" ; variable::stack::push ${vCode} ${RESULT}
variable::new string "third" ; variable::stack::push ${vCode} ${RESULT}

variable::stack::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "third" "$RESULT" "stack::peek first"
variable::stack::pop $vCode ; variable::value "${RESULT}" ; \
    assert::equals "third" "$RESULT" "stack::pop first"
variable::stack::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "$RESULT" "stack::peek second"
variable::stack::pop $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "${RESULT}" "queue::dequeue second"
assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

