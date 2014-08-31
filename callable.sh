#!/bin/bash

# If this file has already been sourced, just return
[ ${CALLABLE_SH+true} ] && return
declare -g CALLABLE_SH=true

. common.sh
. variables.sh
. variables.linkedlist.sh
. evaluator.sh

variable::type::define Callable
variable::type::define Function Callable
variable::type::define BuiltinFunction Function
variable::type::define Lambda Function
variable::type::define Macro Callable

#
# ============================================================
#
# Lambda
#
# the underlying data is an list of [<env token> <formal arguments token> <body token>]
#     <env token> - the environment that the lambda was defined in
#     <formal arguments token> - token of a LinkedList of the argument names
#     <code token> - token to the code
# (lambda (x y)
#     (if (x > y) (* x 2) (* y 3))
# Here, formal args == LinkedList : x y
#       code == LinkedList : if ...
# (lambda (x) x)
# Here, formal args == LinkedList : x
#       code = Identifier x
#

function variable::Lambda::new() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Lambda::new ${@}" ; fi
    variable::new Lambda "${@}"
}

#
# args
#     $1 - the lambda token
#     $2 - the token to a linked list of arguments to pass when calling
#
function variable::Lambda::call() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Lambda::call ${@}" ; fi
    declare lambdaToken="${1}"
    declare passedArgs="${2}"
    variable::type::instanceOfOrExit "${lambdaToken}" Lambda

    variable::LinkedList::length $passedArgs     ; declare passedArgCount="${RESULT}"
    variable::Lambda::getEnv $lambdaToken        ; declare env="${RESULT}"
    variable::Lambda::getFormalArgs $lambdaToken ; declare formalArgs="${RESULT}"
    variable::Lambda::getBody $lambdaToken       ; declare body="${RESULT}"
    variable::LinkedList::length $formalArgs     ; declare formalArgCount="${RESULT}"

    if [[ $passedArgCount -ne $formalArgCount ]]; then
        stderr "lambda: passed arg count (${passedArgCount}) != format arg count (${formalArgCount})"
        exit 1
    fi

    environment::pushScope $env ; declare runningEnv="${RESULT}"
    declare thisKeyToken
    declare thisValueToken
    while ! variable::LinkedList::isEmpty_c "${formalArgs}" ; do
        variable::LinkedList::first "${formalArgs}" ; thisKeyToken="${RESULT}"
        variable::LinkedList::first "${passedArgs}" ; thisValueToken="${RESULT}"

        variable::LinkedList::rest "${formalArgs}" ; formalArgs="${RESULT}"
        variable::LinkedList::rest "${passedArgs}" ; passedArgs="${RESULT}"

        environment::setVariable "${runningEnv}" $thisKeyToken $thisValueToken
    done

    evaluator::eval $runningEnv $body
    RESULT="${RESULT}"
}

function variable::Lambda::getEnv() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Lambda::getEnv ${@}" ; fi
    declare lambdaToken="${1}"
    variable::type::instanceOfOrExit "${lambdaToken}" Lambda

    variable::value $lambdaToken
    declare -a data=(${RESULT})

    RESULT="${data[0]}"
}

function variable::Lambda::getFormalArgs() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Lambda::getFormalArgs ${@}" ; fi
    declare lambdaToken="${1}"
    variable::type::instanceOfOrExit "${lambdaToken}" Lambda

    variable::value $lambdaToken
    declare -a data=(${RESULT})

    RESULT="${data[1]}"
}

function variable::Lambda::getBody() {
    if [[ ${VARIABLES_DEBUG} == 1 ]]; then stderr "variable::Lambda::getBody ${@}" ; fi
    declare lambdaToken="${1}"
    variable::type::instanceOfOrExit "${lambdaToken}" Lambda

    variable::value $lambdaToken
    declare -a data=(${RESULT})

    RESULT="${data[2]}"
}


# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

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


declare env

#
# not using env
#
createTestEnv ; lambdaEnv="${RESULT}"
variable::LinkedList::new ; lambdaArgs="${RESULT}"
appendToList $lambdaArgs Identifier "x" Identifier "y"
variable::LinkedList::new ; lambdaCode="${RESULT}"
appendToList $lambdaCode Identifier '*' Identifier "x" Identifier "y"
variable::Lambda::new "$lambdaEnv $lambdaArgs $lambdaCode" ; lambda="${RESULT}"

variable::LinkedList::new ; callingArgs="${RESULT}"
appendToList $callingArgs Integer 5 Integer 3

variable::Lambda::call $lambda $callingArgs
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 15" "${RESULT}" "((lambda (x y) (* x y) 5 3)"

#
# using env
#
createTestEnv ; lambdaEnv="${RESULT}"
setInEnv $lambdaEnv "y" Integer 10
variable::LinkedList::new ; lambdaArgs="${RESULT}"
appendToList $lambdaArgs Identifier "x"
variable::LinkedList::new ; lambdaCode="${RESULT}"
appendToList $lambdaCode Identifier '*' Identifier "x" Identifier "y"
variable::Lambda::new "$lambdaEnv $lambdaArgs $lambdaCode" ; lambda="${RESULT}"

variable::LinkedList::new ; callingArgs="${RESULT}"
appendToList $callingArgs Integer 5

variable::Lambda::call $lambda $callingArgs
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 50" "${RESULT}" "env(y=10) ((lambda (x) (* x y) 5)"

#variable::printMetadata
#echo "typeof ${vCode}=$(variable::type_p $vCode)"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

