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
function variable::new() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::new ${@}" ; fi
    declare type=$1
    declare value=$2
    declare index=${VARIABLES_INDEX}
    VARIABLES_INDEX=$(( ${VARIABLES_INDEX} + 1 ))

    declare -a metadata=($type)
    VARIABLES_METADATA[index]=${metadata[@]}
    VARIABLES_VALUES[index]=$value

    RESULT=$index
}

function variable::type() {
    declare index=$1
    declare -a metadata=(${VARIABLES_METADATA[$index]})
    RESULT=${metadata[${VARIABLES_OFFSETS[type]}]}
}
function variable::type_p() {
    variable::type ${@}
    echo $RESULT
}

function variable::value() {
    declare index=$1
    RESULT=${VARIABLES_VALUES[index]}
}
function variable::value_p() {
    variable::value ${@}
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

function variable::list::append() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::list::append ${@}" ; fi
    declare list_token=$1
    declare value_token=$2

    if [ "$(variable::type_p ${list_token})" != "list" ]; then
        echo "Cannot append to variable [${list_token}] of type [$(variable::type_p ${list_token})]"
        variable::printMetadata
        exit 1
    fi

    declare -a list_value=(${VARIABLES_VALUES[$list_token]})
    list_value[${#list_value[@]}]=${value_token}
    VARIABLES_VALUES[$list_token]=${list_value[@]}

    RESULT=${#list_value[@]}
}

function variable::list::index() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variables_list::index ${@}" ; fi
    declare list_token=$1
    declare index=$2
    declare -a value=($(variable::value_p $list_token))
    RESULT=${value[$index]}
}

function variable::list::index_p() {
    variable::list::index "${@}"
    echo $RESULT
}

# ignore the following


# == Output
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
