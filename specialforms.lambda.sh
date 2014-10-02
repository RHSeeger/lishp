#!/bin/bash

# If this file has already been sourced, just return
[ ${SPECIALFORMS_LAMBDA_SH+true} ] && return
declare -g SPECIALFORMS_LAMBDA_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/test.sh
. ${BASH_SOURCE%/*}/specialforms.sh
. ${BASH_SOURCE%/*}/callable.lambda.sh

#
# LAMBDA
# (lambda formals expression expression ..._)
#
# A lambda expression evaluates to a procedure. The environment in effect when
# the lambda expression is evaluated is remembered as part of the procedure; it
# is called the closing environment. When the procedure is later called with
# some arguments, the closing environment is extended by binding the variables
# in the formal parameter list to fresh locations, and the locations are filled
# with the arguments according to rules about to be given. The new environment
# created by this process is referred to as the invocation environment.
#
# Once the invocation environment has been constructed, the expressions in the
# body of the lambda expression are evaluated sequentially in it. This means
# that the region of the variables bound by the lambda expression is all of the
# expressions in the body. The result of evaluating the last expression in the
# body is returned as the result of the procedure call.
#
#
#
function evaluator::specialforms::lambda() {
    declare env="${1}"
    declare functionName="${2}" # if
    declare args="${3}" # list of <formal args list>, <expression>,...,<expression>

    variable::LinkedList::length $args ; declare -i length="${RESULT}"
    if [[ $length < 2 ]]; then
        stderr "usage: (if condition true-branch false-branch)"
        exit 1
    fi

    variable::LinkedList::first $args ; declare formalArgs=${RESULT}
    variable::LinkedList::rest $args ; declare expressions=${RESULT}

    variable::Lambda::new "${env} ${formalArgs} ${expressions}"
    RESULT="${RESULT}"
}



# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

#
# no args
# (lambda () 1)
#
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "lambda" 

variable::LinkedList::new ;
variable::LinkedList::append $command $RESULT

appendToList $command Integer 1

evaluator::eval $env $command ; lambda=${RESULT}
variable::toSexp "${lambda}" ; \
    assert::equals "(lambda () 1)" "${RESULT}" "(lambda () 1)"
variable::Lambda::getEnv $lambda ; \
    assert::equals $env $RESULT "<original env> = <stored env>"

#
# with args
# (lambda (a b c) 1)
#
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "lambda" 

variable::LinkedList::new ; argList=${RESULT}
appendToList ${argList} Identifier a Identifier b Identifier c
variable::LinkedList::append $command $argList

appendToList $command Integer 1

evaluator::eval $env $command ; lambda=${RESULT}
variable::toSexp "${lambda}" ; \
    assert::equals "(lambda (a b c) 1)" "${RESULT}" "(lambda (a b c) 1)"

#
# multiple commands
# (lambda () x y)
#
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "lambda" 

variable::LinkedList::new ;
variable::LinkedList::append $command $RESULT

appendToList $command Identifier x Identifier y

evaluator::eval $env $command ; lambda=${RESULT}
variable::toSexp "${lambda}" ; \
    assert::equals "(lambda () x y)" "${RESULT}" "(lambda () x y)"

#
# multiple commands as lists
# (lambda () (+ 1 2) (+ 2 3))
#
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; command="${RESULT}"
appendToList $command Identifier "lambda" 

variable::LinkedList::new ;
variable::LinkedList::append $command $RESULT

variable::LinkedList::new ; sc1=${RESULT}
appendToList $sc1 Identifier + Integer 1 Integer 2
variable::LinkedList::append $command $sc1

variable::LinkedList::new ; sc2=${RESULT}
appendToList $sc2 Identifier + Integer 2 Integer 3
variable::LinkedList::append $command $sc2

evaluator::eval $env $command ; lambda=${RESULT}
variable::toSexp "${lambda}" ; \
    assert::equals "(lambda () (+ 1 2) (+ 2 3))" "${RESULT}" "(lambda () (+ 1 2) (+ 2 3))"




assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

