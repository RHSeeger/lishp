#!/bin/bash

. common.sh
. logger.sh

# TODO: Only set this if it doesn't already exist

#
# Functions that end in _p send their result to stdout (accessed via $(subshell execution))
#     They cannot modify data, so can only be used in getters
#     They should only be used for debugging
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

function _variable::new_p() {
    variable::new "${@}"
    echo "$RESULT"
}

function variable::clone() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::clone ${@}" ; fi

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

    declare from_token="${1}"
    variable::type "${from_token}" ; declare type="${RESULT}"
    variable::value "${from_token}" ; declare value="${RESULT}"

    declare -a metadata=($type)
    VARIABLES_METADATA[${token}]="${metadata[@]}"
    VARIABLES_VALUES[${token}]="$value"

    RESULT="$token"
}

function variable::set() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::set ${@}" ; fi
    if [[ ${#@} -ne 3 ]]; then
        stderr "Usage: variable::set <variable token> <type> <value>"
        exit 1
    fi

    declare token="$1"
    declare type="$2"
    declare value="$3"
    
    declare -a metadata=($type)
    VARIABLES_METADATA[${token}]="${metadata[@]}"
    VARIABLES_VALUES[${token}]="$value"

    RESULT=$index
}

function variable::type() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::type ${@}" ; fi
    declare index=$1
    if [ ! "${VARIABLES_METADATA[${index}]+isset}" ]; then
        stderr "The variable token [${index}] does not exist"
        exit 1
    fi
    declare -a metadata=(${VARIABLES_METADATA[$index]})
    RESULT=${metadata[${VARIABLES_OFFSETS[type]}]}
}
function _variable::type_p() {
    variable::type "${@}"
    echo "$RESULT"
}

function variable::value() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::value ${@}" ; fi
    declare index="${1}"
    if ! [ "${VARIABLES_VALUES[${index}]+isset}" ]; then
        stderr "The variable token [${index}] does not exist"
        exit 1
    fi
    RESULT=${VARIABLES_VALUES[${index}]}
}

function _variable::value_p() {
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

#
# MAP
# 
# Map commands act on a list data structure, assuming the format
#     <key token> <value token> ... <key token> <value token>
#

#
# containsKey_c <map token> <key>
#
function variable::map::containsKey_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::map::containsKey_c ${@}" ; fi

    declare mapToken="${1}"
    declare key="${2}"
    log "Checking value for token [${mapToken}] =? [${VARIABLES_VALUES[${mapToken}]}]"
    variable::value "${mapToken}" ; declare -a items
    if [[ "${RESULT}" == "" ]]; then items=() ; else items=(${RESULT}) ; fi
    log "RESULT = [${RESULT}]"

    declare size 
    declare max_index
    declare currentKey
    (( size=${#items[@]}, max_index=size-1 ))
    log "Iterating over size=[${size}], max_index=[${max_index}]"
    for ((i=0; i<=max_index; i=i+2)); do
        log "here at i=${i} / items[0]=${items[0]} / items=${items[@]}"
        variable::value "${items[${i}]}" ; currentKey="${RESULT}"
        if [ "${currentKey}" == "${key}" ]; then # found it
            return 0
        fi
    done
    log "containsKey_c returning 1"
    return 1
}

#
# get <map token> <key>
#
function variable::map::get() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::map::get ${@}" ; fi

    declare mapToken="${1}"
    declare key="${2}"
    declare -a items
    variable::value $mapToken
    if [[ "${RESULT}" == "" ]]; then items=() ; else items=(${RESULT}) ; fi
    #stderr "Items (${#items[@]}): ${items[@]}"
    declare size 
    declare max_index
    declare currentKey
    (( size=${#items[@]}, max_index=size-1 ))
    for ((i=0; i<=max_index; i=i+2)); do
        variable::value "${items[${i}]}" ; currentKey="${RESULT}"
        if [ "${currentKey}" == "${key}" ]; then # found it
            variable::value "${items[((${i}+1))]}" ; RESULT="${items[((${i}+1))]}"
            return 0
        fi
    done
    return 1
}

function _variable::map::get_p() {
    if ! variable::map::get "${@}"; then
        stderr "Map does not contain the specified key [${2}]"
        exit 1
    fi
    echo "$RESULT"
}

#
# put <map token> <key token> <value token>
#
# Returns 0 if item was found and replaced, 1 if added
#
function variable::map::put() {
    declare mapToken="${1}"
    declare keyToken="${2}"
    declare valueToken="${3}"

    variable::value $mapToken ; declare -a items
    if [[ "${RESULT}" == "" ]]; then items=() ; else items=(${RESULT}) ; fi
    log "MAP: $(_variable::value_p $mapToken)"
    log "Adding new key/value to items [$keyToken]=[$valueToken] -> ${items[@]}"
    variable::value $keyToken   ; declare key="${RESULT}"
    variable::value $valueToken ; declare value="${RESULT}"

    declare size
    declare max_index
    declare currentKey
    (( size=${#items[@]}, max_index=size-1 ))
    for ((i=0; i<=max_index; i=i+2)); do
        variable::value ${items[${i}]} ; currentKey="${RESULT}"
        if [ "${currentKey}" == "${key}" ]; then # found it
            items[((${i}+1))]="${valueToken}"
            variable::set ${mapToken} list "${items[*]}"
            return 0
        fi
    done

    # Not found, add it to the end of the list
    items["${#items[@]}"]="${keyToken}"
    items["${#items[@]}"]="${valueToken}"
    log "Added new key/value to items [$keyToken]=[$valueToken] -> ${items[@]}"
    variable::set ${mapToken} list "${items[*]}"
    return 1
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
variable::type ${token};    declare type=$RESULT

    case ${type} in
        list)
            echo "${indent}${type}(${token}) :: ["
            variable::value ${token}; declare -a values=($RESULT)
#            echo "${indent}  ${values[@]}"
            for value in ${values[@]}; do
                variable::print ${value} "${indent}  "
            done
            echo "${indent}]"
            # echo "${indent}${type} :: size=${#value[@]} :: ${value[@]}"
            ;;
        string)
            echo "${indent}${type}(${token}) :: [$(_variable::value_p ${token})]"
            ;;
        integer)
            echo "${indent}${type}(${token}) :: [$(_variable::value_p ${token})]"
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
variable::new integer 12 ; \
    declare atomId_1=$RESULT

variable::type $atomId_1 ; \
    assert::equals integer "$RESULT" Type of first atom
variable::type "${atomId_1}" ; \
    assert::equals integer "$RESULT" Type of first atom
variable::value $atomId_1 ; \
    assert::equals 12 "$RESULT" Value of first atom
variable::value $atomId_1 ; \
    assert::equals 12 "$RESULT" Value of first atom

variable::new string "hello there" ; \
    declare atomId_2=$RESULT

variable::type $atomId_2 ; \
    assert::equals string "$RESULT" Type of second atom
variable::value $atomId_2 ; \
    assert::equals "hello there" "$RESULT" Value of second atom
variable::value $atomId_1 ; \
    assert::equals 12 "$RESULT" Value of first atom remains

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

#
# MAP tests
#
variable::new list ; vCode=${RESULT}
variable::new key1 "key one" ; key1=${RESULT}
variable::new value1 "value one" ; value1=${RESULT}
variable::new key2 "key two" ; key2=${RESULT}
variable::new value2 "value two" ; value2=${RESULT}

# stderr "vCode=[${vCode}] key1=[${key1}] value1=[${value1}] key2=[${key2}] value2=[${value2}] "

variable::map::containsKey_c $vCode "no such key"
assert::equals 1 $? "containsKey false"

variable::map::put $vCode $key1 $value1 # put "key one" "value one"
variable::map::containsKey_c $vCode "key one"
assert::equals 0 $? "containsKey one true"
variable::map::get "$vCode" "key one" ; variable::value "${RESULT}" \
    assert::equals "value one" "$RESULT" "get key one"

variable::map::put $vCode $key2 $value2 # put "key two" "value two"
variable::map::containsKey_c $vCode "key two"
assert::equals 0 $? "containsKey two true"
variable::map::get $vCode "key two" ; variable::value "${RESULT}" \
    assert::equals "value two" "$RESULT" "get key two"

variable::map::put $vCode $key1 $value2 # put "key one" "value two"
variable::map::containsKey_c $vCode "key one"
assert::equals 0 $? "containsKey one replaced true"
variable::map::get $vCode "key one" ; variable::value "${RESULT}" \
    assert::equals "value two" "$RESULT" "get key one replaced"

assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

