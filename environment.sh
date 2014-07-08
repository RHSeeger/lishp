#!/bin/bash

#
# Environtments are stored as a list of lists
# Each list is a "call stack", and popped from the list of lists when the current scope is exited
# Each list is of the form 
#    (name-1 variable-token-1 ... name-N variable-token-N)
# Where:
#    name is the name of the variable in the environment
#    variable-key is the token to lookup a value using the variable:: api
#

. common.sh
. variables.sh

#
# environment::new
#
# Creates a brand new environment
# Generally will only be called once at the setup of the interpreter
#
# Returns: The variable-token for the newly created environment
#
function environment::new() {
    variable::new list ; env=${RESULT}
    variable::new list ; variable::list::append ${env} ${RESULT}
    RESULT="${env}"
}

#
# environment::addScope <environment-token>
#
# Adds a new scope to the to the environment
#
# Returns: The same environment variable-token that was passed in
#
function environment::pushScope() {
    declare env="${1}"
    variable::new list ; variable::list::push ${env} ${RESULT}
    RESULT="${env}"
}

#
# environment::popScope <environment-token>
#
# Removes the top level environment from the environment list 
# TODO: Need better names to distinguish "a list of environment lists" and
#       "a list of name value-token pairs"
#
# Returns: The same environment variable-token that was passed in
#
function environment::popScope() {
    declare env="${1}"
    variable::new list ; variable::list::pop ${env} 
    RESULT="${env}"
}

#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair on the top level of the environment
# TODO: MAKE IT WORK
function environment::setVariable() {
    declare env="${1}"
    declare name="${2}"
    declare value_token="${3}"

    declare -a scope=($(variable::list::last_p "${env}"))
    declare size, max_index
    (( size=${#scope[@]}, max_index=size-1 ))
    #declare size=${#scope[@]}
    #declare max_index=((size - 1))
    for ((i=0; i<=max_index; i=i+2)); do
        current_name="${scope[${i}]}"
        if [ "${scope[${i}]}" == "${name}" ]; then # found it
            RESULT="${scope[$(${i}+1)]}"
        fi
    done
}

#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair on the top level of the environment
# TODO: MAKE IT WORK
function environment::lookup() {
    declare env="${1}"
    declare name="${2}"

    declare -a scope=($(variable::list::last_p "${env}"))
    declare size, max_index
    (( size=${#scope[@]}, max_index=size-1 ))
    for ((i=0; i<=max_index; i=i+2)); do
        current_name="${scope[${i}]}"
        if [ "${scope[${i}]}" == "${name}" ]; then # found it
            RESULT="${scope[$(${i}+1)]}"
            return 0
        fi
    done
    return 1
}

#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair whereever it is found in the environment list
# or, if the name in question is not found, adds it to the top level
#
function environment::replaceVariable() {
    declare notImplementedYet=1
}


# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

variable::new list ; env=${RESULT}
variable::new list ; scope=${RESULT}
variable::list::push ${env} ${scope}
variable::new string "the value" ; value=${RESULT}
variable::list::append $scope "theKey"
variable::list::append $scope $value

environment::lookup ${env} "theKey"
assertEquals 0 $? "return code: found"
assertEquals "the value" "${RESULT}"


