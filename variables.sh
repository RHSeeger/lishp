#!/bin/bash

. common.sh

# TODO: Only set this if it doesn't already exist

#
# Functions that end in _p send their result to stdout (accessed via $(subshell execution))
#     They cannot modify data, so can only be used in getters
#
# Functions that end in _c return their result via [return 0/1] to signify true/false
#
# All other functions return their results in the global RESULT
#  

# handle=[type]
if [ -z "${VARIABLES_METADATA}" ]; then
    declare -A VARIABLES_METADATA=()
    declare -A VARIABLES_VALUES=()
    declare VARIABLES_INDEX=0

    declare -A VARIABLES_OFFSETS=([type]=0)

    declare VARIABLES_DEBUG=0
fi

# == GENERAL ==
function variable::new() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::new ${@}" ; fi

    if [[ "${1}" == "-name" ]]; then
        shift
        declare token="${1}"
        shift
    else
        declare token="auto#${VARIABLES_INDEX}"
        VARIABLES_INDEX=$(( ${VARIABLES_INDEX} + 1 ))
    fi

    if [[ "${#@}" -lt 1 || "${#@}" -gt 2 ]]; then
        stderr "Usage: variable::new ?name? <type> <value>"
        exit 1
    fi

    declare type=$1
    if [[ "${#@}" -eq 1 ]]; then
        declare value=""
    else
        declare value="${2}"
    fi

    declare -a metadata=($type)
    VARIABLES_METADATA[${token}]="${metadata[@]}"
    VARIABLES_VALUES[${token}]="$value"

    #echo "Creating a new [$1] of [$2] at index [${index}]"
    #echo "Result=${index}"
    RESULT="$token"
}
function variable::new_p() {
    variable::new "${@}"
    echo "$RESULT"
}

function variable::set() {
    declare token="$1"
    declare type="$2"
    declare value="$3"
    
    declare -a metadata=($type)
    VARIABLES_METADATA[${token}]="${metadata[@]}"
    VARIABLES_VALUES[${token}]="$value"

    RESULT=$index
}

function variable::type() {
    declare index=$1
    declare -a metadata=(${VARIABLES_METADATA[$index]})
    RESULT=${metadata[${VARIABLES_OFFSETS[type]}]}
}
function variable::type_p() {
    variable::type "${@}"
    echo "$RESULT"
}

function variable::value() {
    declare index="${1}"
    RESULT=${VARIABLES_VALUES[${index}]}
}

function variable::value_p() {
    variable::value "${@}"
    echo "$RESULT"
}

# == ATOM ==

# == LIST ==
# 
# Lists are represented as just a list of tokens to variables
#
function variable::list::append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    if [ "$(variable::type_p ${list_token})" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [$(variable::type_p ${list_token})]"
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

    if [ "$(variable::type_p ${list_token})" != "list" ]; then
        stderr "Cannot append to variable [${list_token}] of type [$(variable::type_p ${list_token})]"
        variable::printMetadata
        exit 1
    fi

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    declare -a new_value=("${value_token}" "${list_value[@]}")
    VARIABLES_VALUES[$list_token]=${new_value[@]}

    RESULT=${#list_value[@]}
}

function variable::list::index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list::index ${@}" ; fi
    declare list_token=$1
    if [[ $(variable::type_p $list_token) != "list" ]]; then
        stderr "Cannot use [variable::list::index] on type [$(variable::type_p $list_token)]"
        exit 1
    fi
    declare index=$2
    declare -a value=($(variable::value_p $list_token))
    RESULT=${value[$index]}
}

function variable::list::index_p() {
    variable::list::index "${@}"
    echo "$RESULT"
}

function variable::list::first() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::first ${@}" ; fi
    declare list_token=$1
    if [[ $(variable::type_p $list_token) != "list" ]]; then
        stderr "Cannot use [variable::list::first] on type [$(variable::type_p $list_token)]"
        exit 1
    fi
    variable::list::index ${list_token} 0
}

function variable::list::first_p() {
    variable::list::first "${@}"
    echo "${RESULT}"
}

function variable::list::rest() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::rest ${@}" ; fi
    declare list_token=$1
    if [[ $(variable::type_p $list_token) != "list" ]]; then
        stderr "Cannot use [variable::list::rest] on type [$(variable::type_p $list_token)]"
        exit 1
    fi
    declare -a values=($(variable::value_p $list_token))
    RESULT="${values[@]:1}"
}

function variable::list::rest_p() {
    variable::list::rest "${@}"
    echo "${RESULT}"
}

#
# Returns code 0 if the list is empty, 1 if not
#
function variable::list::isEmpty_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::isEmpty_c ${@}" ; fi
    declare token="${1}"
    if [[ $(variable::type_p "$token") != "list" ]]; then
        stderr "Cannot use [variable::list::isEmpty_c] on type [$(variable::type_p $token)]"
        exit 1
    fi
    declare -a value=($(variable::value_p "${token}"))
    [[ ${#value[@]} -eq 0 ]]
    return $?
}

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
    if [[ $(variable::type_p "$token") != "list" ]]; then
        stderr "Cannot use [variable::stack::pop] on type [$(variable::type_p $token)]"
        exit 1
    fi
    if variable::list::isEmpty_c "${token}" ; then
        stderr "Cannot pop from an empty stack"
        exit 1
    fi

    declare result=$(variable::queue::peek_p "${token}")
    declare type=$(variable::type_p $token)
    declare value=$(variable::list::rest_p $token)
    variable::set "$token" "$type" "$value"
    RESULT="${result}"
}

#
# Returns the most recent item added to the stack (does note remove it)
#
function variable::stack::peek() {
    declare token="${1}"
    if [[ $(variable::type_p "$token") != "list" ]]; then
        stderr "Cannot use [variable::stack::peek] on type [$(variable::type_p $token)]"
        exit 1
    fi
    if variable::list::isEmpty_c $token ; then
        stderr "Cannot peek from an empty stack"
        exit 1
    fi

    declare result=$(variable::list::first_p $token)
    RESULT="${result}"
}
function variable::stack::peek_p() {
    variable::stack::peek "${@}"
    echo "$RESULT"
}

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
    if [[ $(variable::type_p "$token") != "list" ]]; then
        stderr "Cannot use [variable::list::isEmpty_c] on type [$(variable::type_p $token)]"
        exit 1
    fi
    if variable::list::isEmpty_c "${token}" ; then
        stderr "Cannot dequeue from an empty queue"
        exit 1
    fi

    declare result=$(variable::queue::peek_p "${token}")
    declare type=$(variable::type_p $token)
    declare value=$(variable::list::rest_p $token)
    variable::set "$token" "$type" "$value"
    RESULT="${result}"
}

#
# Returns the oldest item added to the queue (does note remove it)
#
function variable::queue::peek() {
    declare token="${1}"
    if [[ $(variable::type_p "$token") != "list" ]]; then
        stderr "Cannot use [variable::list::isEmpty_c] on type [$(variable::type_p $token)]"
        exit 1
    fi
    if variable::list::isEmpty_c $token ; then
        stderr "Cannot peek from an empty queue"
        exit 1
    fi
    # stderr "peeking at list [$(variable::value_p $token)] / first=$(variable::list::first_p $token)"
    declare result=$(variable::list::first_p $token)
    RESULT="${result}"
}
function variable::queue::peek_p() {
    variable::queue::peek "${@}"
    echo "$RESULT"
}


#
# == Output
#
function variable::printMetadata() {
    stderr "VARIABLES_METADATA"
    for key in "${!VARIABLES_METADATA[@]}"; do
        stderr "    [${key}]=[${VARIABLES_METADATA[${key}]}]"
    done
    stderr "VARIABLES_VALUES"
    for key in "${!VARIABLES_VALUES[@]}"; do
        stderr "    [${key}]=[${VARIABLES_VALUES[${key}]}]"
    done
    stderr "VARIABLES_INDEX=${VARIABLES_INDEX}"
}

function variable::print() {
    declare token=$1
    declare indent=$2
    declare type=$(variable::type_p ${token})

    case ${type} in
        list)
            echo "${indent}${type}(${token}) :: ["
            declare -a values=($(variable::value_p ${token}))
#            echo "${indent}  ${values[@]}"
            for value in ${values[@]}; do
                variable::print ${value} "${indent}  "
            done
            echo "${indent}]"
            # echo "${indent}${type} :: size=${#value[@]} :: ${value[@]}"
            ;;
        string)
            echo "${indent}${type}(${token}) :: [$(variable::value_p ${token})]"
            ;;
        integer)
            echo "${indent}${type}(${token}) :: [$(variable::value_p ${token})]"
            ;;
        *)
            stderr "Invalid variable type [${type}] for token [${token}]"
            variable::printMetadata
            exit 1
            ;;
    esac
}


# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi


# == ATOM TESTS ==
variable::new integer 12
declare atomId_1=$RESULT

variable::type $atomId_1
assertEquals integer "$RESULT" Type of first atom
assertEquals integer "$(variable::type_p $atomId_1)" Type of first atom
variable::value $atomId_1
assertEquals 12 "$RESULT" Value of first atom
assertEquals 12 "$(variable::value_p $atomId_1)" Value of first atom

variable::new string "hello there"
declare atomId_2=$RESULT

variable::type $atomId_2
assertEquals string "$RESULT" Type of second atom
variable::value $atomId_2
assertEquals "hello there" "$RESULT" Value of second atom
variable::value $atomId_1
assertEquals 12 "$RESULT" Value of first atom remains

# == LIST TESTS ==
# create a new list
# test its size is 0
# add an atom to list
# test its size is 1
# retrieve value of first item (atom) in list

variable::new list ; vCode=${RESULT}
variable::new identifier "+" ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}

assertEquals list "$(variable::type_p $vCode)" "List type"
assertEquals identifier "$(variable::type_p $(variable::list::index_p $vCode 0))" "List first item type"
assertEquals integer "$(variable::type_p $(variable::list::index_p $vCode 1))" "List first item type"
assertEquals integer "$(variable::type_p $(variable::list::index_p $vCode 2))" "List first item type"

variable::new list ; vCode=${RESULT}
variable::new string "a" ; A=${RESULT} ; variable::list::append ${vCode} $A
variable::new string "b" ; B=${RESULT} ; variable::list::append ${vCode} $B
variable::new string "c" ; C=${RESULT} ; variable::list::append ${vCode} $C

assertEquals "$B" "$(variable::list::index_p $vCode 1)" "index_p"
assertEquals "$A" "$(variable::list::first_p $vCode)" "first_p"
assertEquals "${B} ${C}" "$(variable::list::rest_p $vCode 0)" "rest_p"

variable::new -name "EVAL_RESULT" integer 4 ; declare varname="${RESULT}"
assertEquals "EVAL_RESULT" "${varname}" "Non-auto variable name"
assertEquals integer $(variable::type_p "${varname}") "Non-auto type"
assertEquals 4 $(variable::value_p "${varname}") "Non-auto value"

variable::new list ; vCode=${RESULT}
variable::list::isEmpty_c ${vCode}
assertEquals 0 $? "Return code true (0)"
variable::new identifier "+" ; variable::list::append ${vCode} ${RESULT}
variable::list::isEmpty_c ${vCode}
assertEquals 1 $? "Return code false (1)"

# append
variable::new list ; vCode=${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
assertEquals 5 "$(variable::value_p $(variable::list::index_p $vCode 0))" "append / 0"
assertEquals 2 "$(variable::value_p $(variable::list::index_p $vCode 1))" "append / 1"

#
# STACK tests
#
variable::new list ; vCode=${RESULT}
variable::new string "first" ; variable::stack::push ${vCode} ${RESULT}
variable::new string "second" ; variable::stack::push ${vCode} ${RESULT}
variable::new string "third" ; variable::stack::push ${vCode} ${RESULT}
assertEquals "third" "$(variable::value_p $(variable::stack::peek_p $vCode))" "stack::peek first"
variable::stack::pop $vCode
assertEquals "third" "$(variable::value_p ${RESULT})" "stack::pop first"
assertEquals "second" "$(variable::value_p $(variable::stack::peek_p $vCode))" "stack::peek second"
variable::stack::pop $vCode
assertEquals "second" "$(variable::value_p ${RESULT})" "queue::dequeue second"

#
# QUEUE tests
#
variable::new list ; vCode=${RESULT}
variable::new string "first" ; variable::queue::enqueue ${vCode} ${RESULT}
variable::new string "second" ; variable::queue::enqueue ${vCode} ${RESULT}
variable::new string "third" ; variable::queue::enqueue ${vCode} ${RESULT}
assertEquals "first" "$(variable::value_p $(variable::queue::peek_p $vCode))" "queue:peek first"
variable::queue::dequeue $vCode
assertEquals "first" "$(variable::value_p ${RESULT})" "queue::dequeue first"
assertEquals "second" "$(variable::value_p $(variable::queue::peek_p $vCode))" "queue:peek second"
variable::queue::dequeue $vCode
assertEquals "second" "$(variable::value_p ${RESULT})" "queue::dequeue second"

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

