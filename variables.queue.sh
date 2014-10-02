#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_QUEUE_SH+true} ] && return
declare -g VARIABLES_QUEUE_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/logger.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.atom.sh
. ${BASH_SOURCE%/*}/variables.arraylist.sh

variable::type::define ArrayQueue ArrayList

# == QUEUE ==
# 
# First In / First Out
#
# Queue commands act on a list data structure
#

function variable::ArrayQueue::new() {
    variable::new ArrayQueue "${@}"
}

#
# Adds an item to the queue
#
function variable::ArrayQueue::enqueue() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayQueue::enqueue ${@}" ; fi

    declare token="${1}"
    if ! variable::type::instanceOf "${token}" ArrayQueue ; then
        stderr "Variable [${token}] is not of type ArrayQueue (actual type [${RESULT}])"
        exit 1
    fi

    variable::ArrayList::append "${@}"
}

#
# Removes and returns the oldest item added to the queue
#
function variable::ArrayQueue::dequeue() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::ArrayList::isEmpty_c ${@}" ; fi
    declare token="${1}"

    if ! variable::type::instanceOf "${token}" ArrayQueue ; then
        stderr "Variable [${token}] is not of type ArrayQueue (actual type [${RESULT}])"
        exit 1
    fi

    if variable::ArrayList::isEmpty_c "${token}" ; then
        stderr "Cannot dequeue from an empty queue"
        exit 1
    fi

    variable::ArrayQueue::peek "${token}";    declare result=$RESULT
    variable::type $token;    declare type=$RESULT
    variable::ArrayList::rest $token;    declare value=$RESULT
    variable::set "$token" "$type" "$value"
    RESULT="${result}"
}

#
# Returns the oldest item added to the queue (does note remove it)
#
function variable::ArrayQueue::peek() {
    declare token="${1}"

    if ! variable::type::instanceOf "${token}" ArrayQueue ; then
        stderr "Variable [${token}] is not of type ArrayQueue (actual type [${RESULT}])"
        exit 1
    fi

    if variable::ArrayList::isEmpty_c $token ; then
        stderr "Cannot peek from an empty queue"
        exit 1
    fi
    # stderr "peeking at list [$(variable::value_p $token)] / first=$(variable::ArrayList::first_p $token)"
    variable::ArrayList::first $token;    declare result=$RESULT
    RESULT="${result}"
}
function _variable::ArrayQueue::peek_p() {
    variable::ArrayQueue::peek "${@}"
    echo "$RESULT"
}



# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

#
# QUEUE tests
#
variable::ArrayQueue::new ; vCode=${RESULT}
variable::new String "first" ; variable::ArrayQueue::enqueue ${vCode} ${RESULT}
variable::new String "second" ; variable::ArrayQueue::enqueue ${vCode} ${RESULT}
variable::new String "third" ; variable::ArrayQueue::enqueue ${vCode} ${RESULT}

variable::ArrayQueue::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "first" "$RESULT" "queue:peek first"
variable::ArrayQueue::dequeue $vCode ; variable::value "${RESULT}" ; \
    assert::equals "first" "$RESULT" "queue::dequeue first"
variable::ArrayQueue::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "$RESULT" "queue:peek second"
variable::ArrayQueue::dequeue $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "$RESULT" "queue::dequeue second"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi


