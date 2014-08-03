#!/bin/bash

. common.sh
require logger
provide variables

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
    declare -g -A VARIABLES_METADATA=()
    declare -g -A VARIABLES_VALUES=()
    declare -g VARIABLES_INDEX=0

    declare -g -A VARIABLES_OFFSETS=([type]=0)

    declare -g VARIABLES_DEBUG=0
fi

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

    declare type=$1

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


assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

