#!/bin/bash

n=thing
e=(a 1 b 2 c 3)
a=(A B C)


function call_command_1() {
    name=$1
    declare -a environment=("${!2}")
    declare -a arguments=("${!3}")

    echo all="$@"
    echo name="$name"
    echo environment="${environment[@]}"
    echo arguments="${arguments[@]}"
}

call_command_1 "$n" e[@] a[@]

echo ---------------------

function call_command_2() {
    name=$1
    declare -a environment=(${2})
    declare -a arguments=("${3}")

    echo all="$@"
    echo name="$name"
    echo environment="${environment[@]}"
    echo arguments="${arguments[@]}"
}

call_command_2 "$n" "${e[@]}" "${a[@]}"

echo --------------------
declare -A VALUES
declare -A LISTS
declare RESULT

VALUES[a]=4
VALUES[b]=10
VALUES[c]="function_name"
LISTS[list1]="a list2"
LISTS[list2]="b"

function error() {
    echo Error: $@
    exit 1
}

function list_item_at() {
    # TODO:
    # check that the list exists
    # check that index >= 0

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

function printit() {
    echo $1 / ${VALUES[$1]}
    echo $2 / ${LISTS[$2]}
}
echo LISTS : "${LISTS[@]}"
echo LISTS[list1] : "${LISTS[list1]}"
printit c list1
echo --------------------
list_item_at list1 0
echo RESULT=$RESULT
echo -------------------
list_item_at list1 1
echo RESULT=$RESULT

echo $BASH_SOURCE
echo $0
