#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_STACK_SH+isset} ] && return
declare -g VARIABLES_STACK_SH=true

#

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/logger.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.atom.sh
. ${BASH_SOURCE%/*}/variables.arraylist.sh
. ${BASH_SOURCE%/*}/variables.queue.sh

variable::type::define ArrayStack ArrayList

# == STACK ==
# 
# Last In / First Out
#
# Stack commands act on a list data structure
#

function variable::ArrayStack::new() {
    variable::new ArrayStack "${@}"
}

#
# Adds an item to the stack
#
function variable::ArrayStack::push() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayStack::push ${@}" ; fi
    variable::ArrayList::prepend "${@}"
}

#
# Removes and returns the most recent item added to the stack
#
function variable::ArrayStack::pop() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayStack::pop ${@}" ; fi
    declare token="${1}"

    if ! variable::type::instanceOf "${token}" ArrayStack ; then
        variable::type "${token}"
        stderr "Variable [${token}] is not of type ArrayStack (actual type [${RESULT}])"
        exit 1
    fi

    if variable::ArrayList::isEmpty_c "${token}" ; then
        stderr "Cannot pop from an empty stack"
        exit 1
    fi

    variable::ArrayStack::peek "${token}" ; declare result=$RESULT
    variable::type $token ; declare type=$RESULT
    variable::ArrayList::rest $token ; declare value=$RESULT
    variable::set "$token" "$type" "$value"
    RESULT="${result}"
}

#
# Returns the most recent item added to the stack (does note remove it)
#
function variable::ArrayStack::peek() {
    declare token="${1}"

    if ! variable::type::instanceOf "${token}" ArrayStack ; then
        variable::type "${token}"
        stderr "Variable [${token}] is not of type ArrayStack (actual type [${RESULT}])"
        exit 1
    fi

    if variable::ArrayList::isEmpty_c $token ; then
        stderr "Cannot peek from an empty stack"
        exit 1
    fi

variable::ArrayList::first $token ;    declare result=$RESULT
    RESULT="${result}"
}
function _variable::ArrayStack::peek_p() {
    variable::ArrayStack::peek "${@}"
    echo "$RESULT"
}

# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi


#
# STACK tests
#
variable::ArrayStack::new ; vCode=${RESULT}
variable::new String "first" ; variable::ArrayStack::push ${vCode} ${RESULT}
variable::new String "second" ; variable::ArrayStack::push ${vCode} ${RESULT}
variable::new String "third" ; variable::ArrayStack::push ${vCode} ${RESULT}

variable::ArrayStack::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "third" "$RESULT" "stack::peek first"
variable::ArrayStack::pop $vCode ; variable::value "${RESULT}" ; \
    assert::equals "third" "$RESULT" "stack::pop first"
variable::ArrayStack::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "$RESULT" "stack::peek second"
variable::ArrayStack::pop $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "${RESULT}" "queue::dequeue second"
assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

