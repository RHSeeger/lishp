#!/bin/bash

# If this file has already been sourced, just return
[ ${CALLABLE_LAMBDA_SH+true} ] && return
declare -g CALLABLE_LAMBDA_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.linkedlist.sh
. ${BASH_SOURCE%/*}/specialforms.sh
. ${BASH_SOURCE%/*}/evaluator.sh
. ${BASH_SOURCE%/*}/callable.sh

variable::type::define Lambda Function

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

    variable::debug $body

    declare currentSexp currentResult
    while ! variable::LinkedList::isEmpty_c "${body}" ; do
        variable::LinkedList::first "${body}" ; currentSexp=${RESULT}
        variable::LinkedList::rest "${body}" ; body=${RESULT}
        evaluator::eval $runningEnv $currentSexp
        currentResult=${RESULT}
    done
    RESULT="${currentResult}"
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

function variable::Lambda::toSexp() {
    declare token="${1}"
    variable::Lambda::getEnv $token ; declare env=$RESULT
    variable::Lambda::getFormalArgs $token ; declare args=$RESULT
    variable::Lambda::getBody $token ; declare body=$RESULT

    variable::toSexp $args ; declare argsString=$RESULT
    variable::toSexp $body ; declare bodyString=$RESULT
    declare bodyLen ; (( bodyLen = ${#bodyString} - 2 ))
    bodyString=${bodyString:1:bodyLen}

    RESULT="(lambda ${argsString} $bodyString)"
}

# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

. ${BASH_SOURCE%/*}/test.sh

#
# not using env
#
createTestEnv ; lambdaEnv="${RESULT}"
variable::LinkedList::new ; lambdaArgs="${RESULT}"
appendToList $lambdaArgs Identifier "x" Identifier "y"
variable::LinkedList::new ; lambdaBody="${RESULT}"
variable::LinkedList::new ; lambdaCode="${RESULT}"
appendToList $lambdaCode Identifier '*' Identifier "x" Identifier "y"
variable::LinkedList::append $lambdaBody $lambdaCode
variable::Lambda::new "$lambdaEnv $lambdaArgs $lambdaBody" ; lambda="${RESULT}"

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
variable::LinkedList::new ; lambdaBody="${RESULT}"
variable::LinkedList::new ; lambdaCode="${RESULT}"
appendToList $lambdaCode Identifier '*' Identifier "x" Identifier "y"
variable::LinkedList::append $lambdaBody $lambdaCode
variable::Lambda::new "$lambdaEnv $lambdaArgs $lambdaBody" ; lambda="${RESULT}"

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

