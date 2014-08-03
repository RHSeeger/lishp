#!/bin/bash

. common.sh
require logger
require variables
require variables.arraylist
provide variables.queue


# == QUEUE ==
# 
# First In / First Out
#
# Queue commands act on a list data structure
#

#
# Adds an item to the queue
#
function variable::queue::enqueue() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::queue::enqueue ${@}" ; fi
    variable::list::append "${@}"
}

#
# Removes and returns the oldest item added to the queue
#
function variable::queue::dequeue() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::isEmpty_c ${@}" ; fi
    declare token="${1}"
    variable::type "${token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot use [variable::queue::dequeue] on type [${$RESULT}]"
        exit 1
    fi
    if variable::list::isEmpty_c "${token}" ; then
        stderr "Cannot dequeue from an empty queue"
        exit 1
    fi

    variable::queue::peek "${token}";    declare result=$RESULT
    variable::type $token;    declare type=$RESULT
    variable::list::rest $token;    declare value=$RESULT
    variable::set "$token" "$type" "$value"
    RESULT="${result}"
}

#
# Returns the oldest item added to the queue (does note remove it)
#
function variable::queue::peek() {
    declare token="${1}"

    variable::type "${token}"
    if [ "${RESULT}" != "list" ]; then
        stderr "Cannot use [variable::queue::dequeue] on type [${$RESULT}]"
        exit 1
    fi
    if variable::list::isEmpty_c $token ; then
        stderr "Cannot peek from an empty queue"
        exit 1
    fi
    # stderr "peeking at list [$(variable::value_p $token)] / first=$(variable::list::first_p $token)"
    variable::list::first $token;    declare result=$RESULT
    RESULT="${result}"
}
function _variable::queue::peek_p() {
    variable::queue::peek "${@}"
    echo "$RESULT"
}



# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

#
# QUEUE tests
#
variable::new list ; vCode=${RESULT}
variable::new string "first" ; variable::queue::enqueue ${vCode} ${RESULT}
variable::new string "second" ; variable::queue::enqueue ${vCode} ${RESULT}
variable::new string "third" ; variable::queue::enqueue ${vCode} ${RESULT}

variable::queue::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "first" "$RESULT" "queue:peek first"
variable::queue::dequeue $vCode ; variable::value "${RESULT}" ; \
    assert::equals "first" "$RESULT" "queue::dequeue first"
variable::queue::peek $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "$RESULT" "queue:peek second"
variable::queue::dequeue $vCode ; variable::value "${RESULT}" ; \
    assert::equals "second" "$RESULT" "queue::dequeue second"

assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi


