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
. variables.linkedlist.sh
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

    variable::LinkedList::new ; env="${RESULT}"
    variable::Map::new 
    variable::LinkedList::prepend "${env}" "${RESULT}"
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

    variable::Map::new
    variable::LinkedList::prepend "${env}" "${RESULT}"

    RESULT="${RESULT}"
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

    variable::LinkedList::rest "$1"
    RESULT="${RESULT}"
}

#
# environment::hasValue <env token> <key token>
#
# Returns 0 if the key in question exists in the environment
#
function environment::hasValue() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::getValue ${@}" ; fi

    declare env="${1}"
    declare name="${2}"
    declare scope

    variable::new String "${name}" ; declare keyToken="${RESULT}"

    declare currentEnv="${env}"
    while ! variable::LinkedList::isEmpty_c "${currentEnv}" ; do
        variable::LinkedList::first "${currentEnv}"
        scope="${RESULT}"
        if variable::Map::containsKey_c "${scope}" "${name}" ; then
            return 0
        fi

        variable::LinkedList::rest "${currentEnv}"
        currentEnv="$RESULT"
    done

    return 1
}

#
# environment::getValue <env token> <key token>
#
# Gets the value for a given key in the specified env
# Error if key does not exist
#
function environment::getValue() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::getValue ${@}" ; fi

    declare env="${1}"
    declare name="${2}"
    declare scope

    variable::new String "${name}" ; declare keyToken="${RESULT}"

    declare currentEnv="${env}"
    while ! variable::LinkedList::isEmpty_c "${currentEnv}" ; do
        variable::LinkedList::first "${currentEnv}"
        scope="${RESULT}"
        if variable::Map::containsKey_c "${scope}" "${name}" ; then
            variable::Map::get "${scope}" "${name}"
            return
        fi

        variable::LinkedList::rest "${currentEnv}"
        currentEnv="$RESULT"
    done

    variable::value $name
    stderr "Variable [${name}=${RESULT}] not found in current environment"
    exit 1
}

#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair on the top level of the environment
#
# Returns 0 if the variable already existed (and was changed)
#         1 if the variable is new
#
#
function environment::setVariable() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::setVariable ${@}" ; fi

    declare env="${1}"
    declare name="${2}"
    declare value_token="${3}"

    variable::LinkedList::first "${env}"
    declare scope="${RESULT}"
    declare returnValue

    if variable::Map::containsKey_c "${scope}" "${name}" ; then
        returnValue=0
    else
        returnValue=1
    fi

    variable::Map::put "${scope}" "${name}" "${value_token}"
    RESULT=""
    return $returnValue
}


#
# environment::setVariable <environment-token> <name> <value-token>
#
# Sets a name/variable-token pair whereever it is found in the environment list
# or, if the name in question is not found, adds it to the top level
#
function environment::replaceVariable() {
    if [[ ${ENVIRONMENT_DEBUG} == 1 ]]; then stderr "environment::replaceVariable ${@}" ; fi

    declare env="${1}"
    declare name="${2}"
    declare value_token="${3}"
    declare scope

    variable::new String "${name}" ; declare keyToken="${RESULT}"

    declare currentEnv="${env}"
    while ! variable::LinkedList::isEmpty_c "${currentEnv}" ; do
        variable::LinkedList::first "${currentEnv}"
        scope="${RESULT}"
        if variable::Map::containsKey_c "${scope}" "${name}" ; then
            variable::Map::put "${scope}" "${name}" "${value_token}"
            RESULT=""
            return 0
        fi

        variable::LinkedList::rest "${currentEnv}"
        currentEnv="$RESULT"
    done

    # Wasn't found, add it to the first scope in the env
    variable::LinkedList::first "${env}"
    scope="${RESULT}"
    variable::Map::put "${scope}" "${keyToken}" "${valueToken}"
    RESULT=""
    return 1
}

function environment::print() {
    declare currentEnv="${1}"

    echo "Environment [${currentEnv}]"

    while ! variable::LinkedList::isEmpty_c "${currentEnv}" ; do
        variable::LinkedList::first "${currentEnv}"
        variable::Map::print "${RESULT}"

        variable::LinkedList::rest "${currentEnv}"
        currentEnv="$RESULT"
    done
}

# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

variable::new String "key one" ; key1=${RESULT}
variable::new String "value one" ; value1=${RESULT}
variable::new String "key two" ; key2=${RESULT}
variable::new String "value two" ; value2=${RESULT}
variable::new String "key three" ; key3=${RESULT}
variable::new String "value three" ; value3=${RESULT}
variable::new String "no such key" ; keyUnknown=${RESULT}
declare env1
declare env2
declare env3

environment::new ; env1="${RESULT}"

environment::setVariable "${env1}" $key1 $value1

# Check that we can get the value out
environment::getValue "${env1}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value one" "${RESULT}" "Single variable"

environment::setVariable "${env1}" $key2 $value2

# Check that we can get the previously existing value out
environment::getValue "${env1}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value one" "${RESULT}" "Multiple variables, first"
# And that we can get the new value out
environment::getValue "${env1}" $key2 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Multiple variables, second"

#
# Multiple scope tests
#

environment::pushScope "${env1}" ; env2="${RESULT}"

environment::setVariable "${env2}" $key3 $value3

# Make sure we can get the new value out
environment::getValue "${env2}" $key3 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value three" "${RESULT}" "Second scope"
# And a variable from the original scope
environment::getValue "${env2}" $key2 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Variable from first scope"

# Pop off the second scope
environment::popScope "${env2}" ; env3="${RESULT}"

# and make sure a variable from the first scope is still there
environment::getValue "${env3}" $key2 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Variable from first scope post pop"
# and the variable from the second scope is not
environment::hasValue "${env3}" $key3 ; \
    assert::equals 1 $? "Variable from second scope after we popped it"

#
# Push scope, override a variable, pop scope, and make sure the new value is there
#
environment::new ; env1="$RESULT"
environment::setVariable $env1 $key1 $value1
environment::pushScope "${env1}" ; env2="$RESULT"
environment::setVariable "${env2}" $key1 $value2

environment::getValue "${env1}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Reset variable value, pre pop, old env"

environment::print $env2

environment::getValue "${env2}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Reset variable value, pre pop, new env"

environment::popScope "${env2}" ; env3="$RESULT"

environment::getValue "${env1}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Reset variable value, post pop, old env"
environment::getValue "${env2}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Reset variable value, post pop, new env"
environment::getValue "${env3}" $key1 ; \
    variable::value "${RESULT}" ; \
    assert::equals "value two" "${RESULT}" "Reset variable value, post pop, newest env"

#
#
#

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

