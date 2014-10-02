#!/bin/bash

# If this file has already been sourced, just return
[ ${TEST_SH+true} ] && return
declare -g TEST_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.linkedlist.sh
. ${BASH_SOURCE%/*}/evaluator.sh

#
# Functions to help with testing
# Only sourced for test
#

function createTestEnv() {
    environment::new
    evaluator::setup_builtins "${RESULT}"
}

function setInEnv() {
    declare env="${1}"
    declare name="${2}"
    declare type="${3}"
    declare value="${4}"
    variable::new Identifier "${name}" ; declare nameToken="${RESULT}"
    variable::new "${type}" "${value}" ; declare valueToken="${RESULT}"
    environment::setVariable "${env}" "${nameToken}" "${valueToken}"

    variable::new Identifier "${name}"
}

function appendToList() {
    declare listToken="${1}"
    declare -a items=("${@:2}")
    declare -i size
    declare -i max_index
    declare currentType
    declare currentValue 

    (( size=${#items[@]}, max_index=size-1 ))
    if ((size % 2 != 0)); then
        stderr "appendToList: number of items to add to list not even"
        exit 1
    fi
    for ((i=0; i<=max_index; i=i+2)); do
        currentType="${items[${i}]}"
        currentValue="${items[((i+1))]}"
        variable::new "${currentType}" "${currentValue}"
        variable::LinkedList::append "${listToken}" "${RESULT}"
    done
}
