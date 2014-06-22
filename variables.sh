#!/bin/bash

# TODO: Only set this if it doesn't already exist

# handle=[type]
declare -a VARIABLES_METADATA=()
declare -a VARIABLES_VALUES=()
declare VARIABLES_INDEX=0

declare -A VARIABLES_OFFSETS=([type]=0)
# == ATOMS ==
function atom_new() {
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

function variable_value() {
    declare index=$1
    RESULT=${VARIABLES_VALUES[index]}
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
function list_new() {
    echo $VARIABLES_INDEXES[PAIRS]
}

function list_length() {
    declare list_name=$1
    declare list_index=$2
    declare tmp
    declare value_key
    declare value
    RESULT=""

    while true ; do
        tmp=(${LISTS[$list_name]})
        echo tmp=${tmp[@]}
        value_key=${tmp[0]}
        echo value_key=$value_key

        if [ $list_index == 0 ] ; then # We're at the right index, return the value
            value=${VALUES[$value_key]}
            echo value=$value
            RESULT=${value}
            return 1
        fi
        if [ ${#tmp[@]} -lt 2 ] ; then
            error "The list at ${list_name} had less than 2 elements"
        fi
        list_name=${tmp[1]}
        echo new list name = "${list_name}"
        list_index=$(( $list_index - 1 ))
        echo new index = ${list_index}
    done
}

function list_index() {
    declare list_name=$1
    declare list_index=$2
    declare tmp
    declare value_key
    declare value
    RESULT=""

    while true ; do
        tmp=(${PAIRS[$list_name]})
        echo tmp=${tmp[@]}
        value_key=${tmp[0]}
        echo value_key=$value_key

        if [ $list_index == 0 ] ; then # We're at the right index, return the value
            value=${ATOMS[$value_key]}
            echo value=$value
            RESULT=${value}
            return 1
        fi
        if [ ${#tmp[@]} -lt 2 ] ; then
            error "The list at ${list_name} had less than 2 elements"
        fi
        list_name=${tmp[1]}
        echo new list name = "${list_name}"
        list_index=$(( $list_index - 1 ))
        echo new index = ${list_index}
    done
}

if [ $0 != $BASH_SOURCE ]; then
    return
fi

function assertEquals() {
    declare expect=$1
    declare actual=$2
    declare message=${@:3}
    if [ "$expect" != "$actual" ]; then
        echo "('$expect' != '$actual') $message"
    fi
}

# == ATOM TESTS ==
atom_new integer 12
declare atomId_1=$RESULT

variable_type $atomId_1
assertEquals integer "$RESULT" Type of first atom
variable_value $atomId_1
assertEquals 12 "$RESULT" Value of first atom

atom_new string "hello there"
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
