#!/bin/bash

. common.sh

# TODO: Only set this if it doesn't already exist

# handle=[type]
if [ -z "${VARIABLES_METADATA}" ]; then
    declare -a VARIABLES_METADATA=()
    declare -a VARIABLES_VALUES=()
    declare VARIABLES_INDEX=0

    declare -A VARIABLES_OFFSETS=([type]=0)

    declare VARIABLES_DEBUG=0
fi

# == ATOMS ==
function variable_new() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_new ${@}" ; fi
    declare type=$1
    declare value=$2
    declare index=${VARIABLES_INDEX}
    VARIABLES_INDEX=$(( ${VARIABLES_INDEX} + 1 ))

    declare -a metadata=($type)
    VARIABLES_METADATA[index]=${metadata[@]}
    VARIABLES_VALUES[index]=$value

    RESULT=$index
}

function variable_type() {
    declare index=$1
    declare -a metadata=(${VARIABLES_METADATA[$index]})
    RESULT=${metadata[${VARIABLES_OFFSETS[type]}]}
}
function variable_type_p() {
    variable_type ${@}
    echo $RESULT
}

function variable_value() {
    declare index=$1
    RESULT=${VARIABLES_VALUES[index]}
}
function variable_value_p() {
    variable_value ${@}
    echo $RESULT
}

# == LISTS ==
# (type id type id)
#     pair with both first and second values
# (type id)
#     pair with only a first value (ie, at the end of a list)
# ()
#     empty pair
# whereL
#     type = atom|pair
#     id = index int VARIABLES_(ATOMS_TYPE|ATOMS_VALUES|PAIRS)

function variable_list_append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list_append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    if [ "$(variable_type_p ${list_token})" != "list" ]; then
        echo "Cannot append to variable [${list_token}] of type [$(variable_type_p ${list_token})]"
        variable_print_metadata
        exit 1
    fi

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    list_value[${#list_value[@]}]=${value_token}
    VARIABLES_VALUES[$list_token]=${list_value[@]}

    RESULT=${#list_value[@]}
}

function variable_list_index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list_index ${@}" ; fi
    declare list_token=$1
    declare index=$2
    declare -a value=($(variable_value_p $list_token))
    RESULT=${value[$index]}
}

function variable_list_index_p() {
    variable_list_index "${@}"
    echo $RESULT
}

# ignore the following


# == Output
function variable_print_metadata() {
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

function variable_print() {
    declare token=$1
    declare indent=$2
    declare type=$(variable_type_p ${token})

    case ${type} in
        list)
            echo "${indent}${type}(${token}) :: ["
            declare -a values=($(variable_value_p ${token}))
#            echo "${indent}  ${values[@]}"
            for value in ${values[@]}; do
                variable_print ${value} "${indent}  "
            done
            echo "${indent}]"
            # echo "${indent}${type} :: size=${#value[@]} :: ${value[@]}"
            ;;
        string)
            echo "${indent}${type}(${token}) :: [$(variable_value_p ${token})]"
            ;;
        integer)
            echo "${indent}${type}(${token}) :: [$(variable_value_p ${token})]"
            ;;
        *)
            stderr "Invalid variable type [${type}] for token [${token}]"
            variable_print_metadata
            exit 1
            ;;
    esac
}


# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi


# == ATOM TESTS ==
variable_new integer 12
declare atomId_1=$RESULT

variable_type $atomId_1
assertEquals integer "$RESULT" Type of first atom
assertEquals integer "$(variable_type_p $atomId_1)" Type of first atom
variable_value $atomId_1
assertEquals 12 "$RESULT" Value of first atom
assertEquals 12 "$(variable_value_p $atomId_1)" Value of first atom

variable_new string "hello there"
declare atomId_2=$RESULT

variable_type $atomId_2
assertEquals string "$RESULT" Type of second atom
variable_value $atomId_2
assertEquals "hello there" "$RESULT" Value of second atom
variable_value $atomId_1
assertEquals 12 "$RESULT" Value of first atom remains

# == LIST TESTS ==
# create a new list
# test its size is 0
# add an atom to list
# test its size is 1
# retrieve value of first item (atom) in list

variable_new list ; vCode=${RESULT}
variable_new identifier "+" ; variable_list_append ${vCode} ${RESULT}
variable_new integer 5 ; variable_list_append ${vCode} ${RESULT}
variable_new integer 2 ; variable_list_append ${vCode} ${RESULT}

assertEquals list "$(variable_type_p $vCode)" "List type"
assertEquals identifier "$(variable_type_p $(variable_list_index_p $vCode 0))" "List first item type"
assertEquals integer "$(variable_type_p $(variable_list_index_p $vCode 1))" "List first item type"
assertEquals integer "$(variable_type_p $(variable_list_index_p $vCode 2))" "List first item type"
