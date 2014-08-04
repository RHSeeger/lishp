#!/bin/bash

# If this file has already been sourced, just return
[ ${ENVIRONMENT_SH+isset} ] && return
declare -g ENVIRONMENT_SH=true

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
. variables.arraylist.sh
. variables.stack.sh
. variables.queue.sh
. variables.map.sh


declare -g ENVIRONMENT_DEBUG=0

# TODO: This needs to use a LinkedList implementation for the base list of scopes
#       Each scope, on the other hand, should be a Map

#
# environment::new
#
# Creates a brand new environment
# Generally will only be called once at the setup of the interpreter
#
# Returns: The variable-token for the newly created environment
#
function environment::new() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::new ${@}" ; fi

    variable::new list ; env=${RESULT}
    variable::new list ; variable::stack::push "${env}" "${RESULT}"
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
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::pushScope ${@}" ; fi

    declare env="${1}"
    variable::new list ; variable::stack::push "${env}" "${RESULT}"
    RESULT=${env}
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
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::popScope ${@}" ; fi

    declare env="${1}"
    variable::new list ; variable::stack::pop ${env} 
    RESULT="${env}"
}

#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair on the top level of the environment
# TODO: MAKE IT WORK
function environment::setVariable() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::setVariable ${@}" ; fi

    declare env="${1}"
    declare name="${2}"
    declare value_token="${3}"

    variable::new string "${name}" ; declare nameToken="${RESULT}"

    variable::value "${env}" ; declare -a scopes=($RESULT)
    declare -i size
    declare -i max_index
    declare -i i
    (( size=${#scopes[@]}, max_index=size-1 ))
    for ((i=0; i<=max_index; i=i+1)); do
        declare currentScope="${scopes[${i}]}"
        if variable::map::containsKey_c "${currentScope}" "${name}" ; then
            variable::map::put "${currentScope}" "${nameToken}" "${value_token}"
            return 0
        fi
    done

    # Add it to the top level scope
    variable::stack::peek "${env}"
    variable::map::put "${RESULT}" "${nameToken}" "${value_token}"
    return 1
}

#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair on the top level of the environment
# TODO: MAKE IT WORK
function environment::lookup() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::lookup ${@}" ; fi

    declare env="${1}"
    declare name="${2}"

    variable::value "${env}" ; declare -a scopes=($RESULT)

    declare -i size
    declare -i max_index
    declare currentScope
    (( size=${#scopes[@]}, max_index=size-1 ))
    declare -i i
    for (( i=0; i<=max_index; i=i+1 )); do
        currentScope="${scopes[${i}]}"
        if variable::map::containsKey_c "${currentScope}" "${name}" ; then
            variable::map::get "${currentScope}" "${name}"
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
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::replaceVariable ${@}" ; fi

    declare notImplementedYet=1
}

function environment::print() {
    declare env=$1

    variable::value "${env}" ; declare -a scopes=($RESULT)
    echo "Environment [${env}=${scopes[@]}]"

    declare -i size
    declare -i max_index
    (( size=${#scopes[@]}, max_index=size-1 ))
    declare -i i
    for (( i=0; i<=max_index; i+=1 )); do
        declare currentScope="${scopes[${i}]}"
        variable::map::print "${currentScope}" "    "
    done
}

# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

environment::new ; declare env="${RESULT}"

variable::new string "valueOne"
environment::setVariable "${env}" "variableOne" "${RESULT}"

# Check that we can get the value out
environment::lookup "${env}" "variableOne" ; \
    variable::value "${RESULT}" ; \
    assert::equals "valueOne" "${RESULT}" "Single variable"

variable::new string "valueTwo"
environment::setVariable "${env}" "variableTwo" "${RESULT}"

# Check that we can get the previously existing value out
environment::lookup "${env}" "variableOne" ; \
    variable::value "${RESULT}" ; \
    assert::equals "valueOne" "${RESULT}" "Multiple variables, first"
# And that we can get the new value out
environment::lookup "${env}" "variableTwo" ; \
    variable::value "${RESULT}" ; \
    assert::equals "valueTwo" "${RESULT}" "Multiple variables, second"

#
# Multiple scope tests
#

environment::pushScope "${env}"

variable::new string "valueThree"
environment::setVariable "${env}" "variableThree" "${RESULT}"

# Make sure we can get the new value out
environment::lookup "${env}" "variableThree" ; \
    variable::value "${RESULT}" ; \
    assert::equals "valueThree" "${RESULT}" "Second scope"
# And a variable from the original scope
environment::lookup "${env}" "variableTwo" ; \
    variable::value "${RESULT}" ; \
    assert::equals "valueTwo" "${RESULT}" "Variable from first scope"

# Pop off the second scope
environment::popScope "${env}"
# and make sure a variable from the first scope is still there
environment::lookup "${env}" "variableTwo" ; \
    variable::value "${RESULT}" ; \
    assert::equals "valueTwo" "${RESULT}" "Variable from first scope post pop"
# and the variable from the second scope is not
environment::lookup "${env}" "variableThree" ; \
    assert::equals 1 $? "Variable from second scope after we popped it"

#
# Push scope, override a variable, pop scope, and make sure the new value is there
#
environment::pushScope "${env}"

variable::new string "value override"
environment::setVariable "${env}" "variableOne" "${RESULT}"
environment::popScope "${env}"

environment::lookup "${env}" "variableOne" ; \
    variable::value "${RESULT}" ; \
    assert::equals "value override" "${RESULT}" "Multiple variables, first"

#
#
#

assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

