#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_MAP_SH+true} ] && return
declare -g VARIABLES_MAP_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/logger.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.arraylist.sh

variable::type::define Map ArrayList

#
# MAP
# 
# Map commands act on a list data structure, assuming the format
#     <key token> <value token> ... <key token> <value token>
#

function variable::Map::new() {
    variable::new Map "${@}"
}


#
# containsKey_c <map token> <key token>
#
function variable::Map::containsKey_c() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Map::containsKey_c ${@}" ; fi

    declare mapToken="${1}"
    declare keyToken="${2}"

    variable::value "${mapToken}" ; declare -a items
    if [[ "${RESULT}" == "" ]]; then items=() ; else items=(${RESULT}) ; fi

    variable::value "${keyToken}" ; declare key="${RESULT}"

    declare size 
    declare max_index
    declare currentKey
    (( size=${#items[@]}, max_index=size-1 ))
    declare -i i
    for ((i=0; i<=max_index; i=i+2)); do
        variable::value "${items[${i}]}" ; currentKey="${RESULT}"
        if [ "${currentKey}" == "${key}" ]; then
            return 0
        fi
    done

    return 1
}

#
# get <map token> <key token>
#
function variable::Map::get() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Map::get ${@}" ; fi

    declare mapToken="${1}"
    declare keyToken="${2}"
    variable::value "${keyToken}" ; declare key="${RESULT}"

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

function _variable::Map::get_p() {
    if ! variable::Map::get "${@}"; then
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
function variable::Map::put() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Map::put ${@}" ; fi

    declare mapToken="${1}"
    declare keyToken="${2}"
    declare valueToken="${3}"

    variable::value $mapToken ; declare -a items
    if [[ "${RESULT}" == "" ]]; then items=() ; else items=(${RESULT}) ; fi
    log "MAP: $(_variable::value_p $mapToken)"
    log "Adding new key/value to items [$keyToken]=[$valueToken] -> ${items[@]:+${items[@]}}"
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
            variable::set ${mapToken} ArrayList "${items[*]}"
            return 0
        fi
    done

    # Not found, add it to the end of the list
    items["${#items[@]}"]="${keyToken}"
    items["${#items[@]}"]="${valueToken}"
    log "Added new key/value to items [$keyToken]=[$valueToken] -> ${items[@]}"
    variable::set ${mapToken} ArrayList "${items[*]}"
    return 1
}

#
# DEBUGGING
#

function variable::Map::print() {
    declare mapToken="${1}"
    declare indent="${2-}"
    
    variable::value $mapToken ; declare -a items
    if [[ "${RESULT}" == "" ]]; then 
        items=() 
        echo "${indent}MAP [${mapToken}=()]"
    else 
        items=(${RESULT})
        echo "${indent}MAP [${mapToken}=(${items[@]})]"
    fi

    

    declare size
    declare max_index
    declare currentKey
    declare currentValue 

    (( size=${#items[@]}, max_index=size-1 ))
    for ((i=0; i<=max_index; i=i+2)); do
        variable::value ${items[${i}]} ; currentKey="${RESULT}"
        variable::value ${items[((i+1))]} ; currentValue="${RESULT}"
        echo "${indent}    [${currentKey}]=[${currentValue}]"
    done
}

function variable::Map::debug() {
    declare token="${1}"
    
    variable::value $mapToken
    if [[ "${RESULT}" == "" ]]; then
        RESULT="{}"
        return
    fi

    declare -a items=("${RESULT[@]}")

    declare size declare max_index
    declare currentKey
    declare currentValue 
    declare -a formatted=()

    (( size=${#items[@]}, max_index=size-1 ))
    for ((i=0; i<=max_index; i=i+2)); do
        variable::value ${items[${i}]} ; currentKey="${RESULT}"
        variable::value ${items[((i+1))]} ; currentValue="${RESULT}"
        formatted+=("${currentKey}=${currentValue}")
    done

    variable::debug::join ", " "${formatted[@]}"
    RESULT="{$RESULT}"
}

# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi


#
# MAP tests
#
variable::Map::new ; vCode=${RESULT}
variable::new String "key one" ; key1=${RESULT}
variable::new String "value one" ; value1=${RESULT}
variable::new String "key two" ; key2=${RESULT}
variable::new String "value two" ; value2=${RESULT}
variable::new String "no such key" ; keyUnknown=${RESULT}

# stderr "vCode=[${vCode}] key1=[${key1}] value1=[${value1}] key2=[${key2}] value2=[${value2}] "

variable::Map::containsKey_c $vCode $keyUnknown
assert::equals 1 $? "containsKey false"

variable::Map::put $vCode $key1 $value1 # put "key one" "value one"
variable::Map::containsKey_c $vCode $key1
assert::equals 0 $? "containsKey one true"
variable::Map::get "$vCode" $key1 ; variable::value "${RESULT}" \
    assert::equals "value one" "$RESULT" "get key one"

variable::Map::put $vCode $key2 $value2 # put "key two" "value two"
variable::Map::containsKey_c $vCode $key2
assert::equals 0 $? "containsKey two true"
variable::Map::get $vCode $key2 ; variable::value "${RESULT}" \
    assert::equals "value two" "$RESULT" "get key two"

variable::Map::put $vCode $key1 $value2 # put "key one" "value two"
variable::Map::containsKey_c $vCode $key1
assert::equals 0 $? "containsKey one replaced true"
variable::Map::get $vCode $key1 ; variable::value "${RESULT}" \
    assert::equals "value two" "$RESULT" "get key one replaced"


assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

