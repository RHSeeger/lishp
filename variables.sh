#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_SH+true} ] && return
declare -g VARIABLES_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/logger.sh

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
declare -g -A VARIABLES_METADATA=()
declare -g -A VARIABLES_VALUES=()
declare -g VARIABLES_INDEX=0

declare -g -A VARIABLES_OFFSETS=([type]=0)

declare -g VARIABLES_DEBUG=0

declare -g -A VARIABLES_TYPES=()

# == GENERAL ==
function variable::new() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::new ${@}" ; fi
 
    declare token
    if [[ "${1}" == "-name" ]]; then
        shift
        token="${1}"
        shift
    else
        token="auto#${VARIABLES_INDEX}"
        VARIABLES_INDEX=$(( ${VARIABLES_INDEX} + 1 ))
    fi

    if [[ "${#@}" -lt 1 || "${#@}" -gt 2 ]]; then
        stderr "Usage: variable::new ?name? <type> <value>"
        exit 1
    fi

    declare type="${1}"
    if [ ! ${VARIABLES_TYPES[${type}]+isset} ] ; then
        stderr "Unknown variable type [${type}]"
        exit 1
    fi

    if [[ "${#@}" -eq 1 ]]; then
        declare value=""
    else
        declare value="${2}"
    fi

    declare -a metadata=($type)
    VARIABLES_METADATA["${token}"]="${metadata[@]}"
    VARIABLES_VALUES["${token}"]="$value"

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

#
# variable::set <variable token> <type> <value>
#
function variable::set() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::set ${@}" ; fi
    if [[ ${#@} -ne 3 ]]; then
        stderr "Usage: variable::set <variable token> <type> <value>"
        exit 1
    fi

    declare token="$1"
    declare type="$2"
    declare value="$3"
    
    if [ ! ${VARIABLES_TYPES[${type}]+isset} ] ; then
        stderr "Unknown variable type [${type}]"
        exit 1
    fi


    declare -a metadata=($type)
    VARIABLES_METADATA[${token}]="${metadata[@]}"
    VARIABLES_VALUES[${token}]="$value"

    RESULT=""
}

#
# TYPES
#
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

function variable::type::define() {
    declare typeName="${1}"
    declare -a typeParents=()

    # declare -g VARIABLES_TYPES=()
    if [ ${VARIABLES_TYPES[${typeName}]+isset} ] ; then
        stderr "Variable type [${typeName}] already defined"
        exit 1
    fi

    declare -a superTypes
    if [ ${2+isset} ] ; then
        declare typeParent="${2}"
        if [ ! ${VARIABLES_TYPES[$typeParent]+true} ] ; then
            stderr "Variable type [${typeName}] declare unknown parent type [${typeParent}]"
            exit 1
        fi
        typeParents+=("${typeParent}")
        typeParents+=(${VARIABLES_TYPES[${typeParent}]})
        VARIABLES_TYPES[${typeName}]="${typeParents[@]}"
    else
        VARIABLES_TYPES[${typeName}]=""
    fi
}

#
# Returns true (0) if the variable is of the specified type or any of its supertypes
#
function variable::type::instanceOf() {
    declare token="${1}"
    declare expectedType="${2}"

    if variable::type::exactlyA "${token}" "${expectedType}" ; then
        return 0
    fi

    variable::type "${token}"
    declare actualType="${RESULT}"

    declare -a actualSuperTypes=(${VARIABLES_TYPES[$actualType]})
    if [ ${#actualSuperTypes[@]} -lt 1 ] ; then return 1 ; fi

    declare superType
    for superType in "${actualSuperTypes[@]}"; do
        if [ "${expectedType}" == "${superType}" ] ; then
            return 0
        fi
    done
    
    return 1
}

function variable::type::instanceOfOrExit() {
    declare valueToken="${1}"
    declare expectedType="${2}"
    if ! variable::type::instanceOf "${valueToken}" "${expectedType}" ; then
        variable::type "${valueToken}"
        stderr "Variable [${valueToken}] is not of type [${expectedType}] (actual type [${RESULT}])"
        exit 1
    fi
}

#
# Returns true (0) if the variable is of the specified type
#
function variable::type::exactlyA() {
    declare token="${1}"
    declare expectedType="${2}"

    if [ ! ${VARIABLES_TYPES[$expectedType]+true} ] ; then
        stderr "Unknown type [${expectedType}]"
        exit 1
    fi

    variable::type "${token}"
    declare actualType="${RESULT}"

    if [ "${actualType}" == "${expectedType}" ]; then
        return 0
    else
        return 1
    fi
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

function variable::debug() {
    declare token="${1}"

    variable::type $token ; declare type=$RESULT

    if functionExists "variable::${type}::debug"; then
        eval "variable::${type}::debug ${token}"
        RESULT=$RESULT
        return
    fi
    
    if [[ -z ${VARIABLES_TYPES[${type}]} ]]; then
        variable::debug::simple $token
        RESULT=$RESULT
        return
    fi

    declare -a actualSuperTypes=(${VARIABLES_TYPES[$type]})
    declare superType
    for superType in "${actualSuperTypes[@]}"; do
        if functionExists "variable::${superType}::debug"; then
            eval "variable::${superType}::debug ${token}"
            RESULT=$RESULT
            return
        fi
    done

    variable::debug::simple $token
    RESULT=$RESULT
}

function variable::debug::simple() {
    declare token="${1}"
    variable::type "${token}"
    declare type="${RESULT}"
    variable::value "${token}"
    declare value="${RESULT}"
    RESULT="${type} :: ${value}"
}

function variable::debug::join() {
    declare joinChar=${1}

    if [[ ${#@} == 1 ]]; then 
        RESULT=""
        return
    fi
    if [[ ${#@} == 2 ]]; then
        RESULT="${2}"
        return
    fi

    declare -a items=("${@:2}")
    declare size declare max_index
    RESULT="${2}"

    (( size=${#items[@]}, max_index=size-1 ))
    for (( i=1; i<=max_index; i+=1 )); do
        RESULT="${RESULT}${joinChar}${items[$i]}"
    done
}

function variable::toSexp() {
    declare token="${1}"
    variable::type $token ; declare type=$RESULT

    if functionExists "variable::${type}::toSexp"; then
        eval "variable::${type}::toSexp ${token}"
        RESULT=$RESULT
        return
    fi
    
    if [[ -z ${VARIABLES_TYPES[${type}]} ]]; then
        variable::debug $token
        RESULT=$RESULT
        return
    fi

    declare -a actualSuperTypes=(${VARIABLES_TYPES[$type]})
    declare superType
    for superType in "${actualSuperTypes[@]}"; do
        if functionExists "variable::${superType}::toSexp"; then
            eval "variable::${superType}::toSexp ${token}"
            RESULT=$RESULT
            return
        fi
    done

    variable::debug $token
    RESULT=$RESULT
}

#
# == Output
#
function variable::printMetadata() {
    stderr "VARIABLES_METADATA"
    declare keys
    keys=$(for var in "${!VARIABLES_METADATA[@]}"; do echo "$var"; done | sort -n)
    for key in ${keys}; do
        stderr "    [${key}]=[${VARIABLES_METADATA[${key}]}]"
    done
    stderr "VARIABLES_VALUES"
    keys=$(for var in "${!VARIABLES_VALUES[@]}"; do echo "$var"; done | sort -n)
    for key in ${keys}; do
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

declare testToken

variable::type::define atom
variable::type::define string atom
variable::type::define number atom
variable::type::define integer number

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


# exactlyA
variable::new integer ; \
    testToken="${RESULT}"
variable::type $testToken
variable::type::exactlyA "${testToken}" integer
assert::equals 0 $? "exactlyA same"
variable::type::exactlyA "${testToken}" number
assert::equals 1 $? "exactlyA super"
variable::type::exactlyA "${testToken}" string
assert::equals 1 $? "exactlyA other"

# instanceOf
variable::new number ; \
    testToken="${RESULT}"
variable::type $testToken
variable::type::instanceOf "${testToken}" integer
assert::equals 1 $? "number instanceOf integer"
variable::type::instanceOf "${testToken}" number
assert::equals 0 $? "number instanceOf number"
variable::type::instanceOf "${testToken}" atom
assert::equals 0 $? "number instanceOf atom"
variable::type::instanceOf "${testToken}" string
assert::equals 1 $? "number instanceOf string"


assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

