#!/bin/bash

# If this file has already been sourced, just return
[ ${EVALUATOR_SH+true} ] && return
declare -g EVALUATOR_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/callable.sh
. ${BASH_SOURCE%/*}/specialforms.sh
. ${BASH_SOURCE%/*}/specialforms.lambda.sh
. ${BASH_SOURCE%/*}/environment.sh
. ${BASH_SOURCE%/*}/evaluator.functions.builtin.sh

declare -g EVALUATOR_DEBUG=0

# We declare this so that we have a variable we can use over an over,
# rather than creating a new variable each time we need a result
# declare -g EVALUATOR_VARIABLE="EVAL_RESULT"
# variable::new -name "${EVALUATOR_VARIABLE}" Nil ""

#
# eval <env token> <expr token>
#
function evaluator::eval() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval ${@}" ; fi

    declare envToken="${1}"
    declare exprToken="${2}"

    if variable::type::instanceOf "${exprToken}" Atom; then
        variable::clone "${exprToken}"
        RESULT="${RESULT}"
        return
    elif variable::type::instanceOf "${exprToken}" Callable; then
        variable::clone "${exprToken}"
        RESULT="${RESULT}"
        return
    elif variable::type::instanceOf "${exprToken}" Identifier; then
        environment::getValue "${envToken}" "${exprToken}"
        RESULT="${RESULT}"
        return
    elif variable::type::instanceOf "${exprToken}" LinkedList; then
        evaluator::eval_list "${@}"
        RESULT="${RESULT}"
        return
    else 
        stderr "evaluator::eval / Unhandled type for token [$exprToken]"
        variable::printMetadata
        exit 1
    fi
    stderr "should never get here"
    exit 1
}

function evaluator::evalFromLinkedList() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval ${@}" ; fi

    declare envToken="${1}"
    declare expressions="${2}" ;# A LinkedList of expressions

    # evaluate expressions
    declare currentSexp currentResult
    while ! variable::LinkedList::isEmpty_c "${expressions}" ; do
        variable::LinkedList::first "${expressions}" ; currentSexp=${RESULT}
        variable::LinkedList::rest "${expressions}" ; expressions=${RESULT}
        evaluator::eval $envToken $currentSexp
        currentResult=${RESULT}
    done
    RESULT="${currentResult}"
    return 0
}

function evaluator::eval_list() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval_list ${@}" ; fi

    declare envToken="${1}"
    declare listToken="${2}"

    if ! variable::type::instanceOf $listToken LinkedList; then
        stderr "evaluator::eval_list / must be a list"
        exit 1
    fi

    variable::LinkedList::length "${listToken}"
    if [[ "${RESULT}" -eq 0 ]]; then 
        variable::new Nil ""
        RESULT="${RESULT}"
        return
    fi

    variable::LinkedList::first "${listToken}"
    evaluator::eval "${envToken}" "${RESULT}" ; declare headItem="${RESULT}"
    variable::type "${headItem}" ; declare headType="${RESULT}"
    variable::value "${headItem}" ; declare headValue="${RESULT}"

    # variable::toSexp $listToken
    # variable::debug $headItem

    variable::LinkedList::rest $listToken ; declare rest="${RESULT}"

    case "${headType}" in
        BuiltinFunction)
            evaluator::call_builtinFunction "${envToken}" "${headItem}" "${rest}"
            RESULT="${RESULT}"
            ;;
        BuiltinMacro) # Lookup the identifier in the environment and return it's value
            evaluator::call_builtinMacro "${envToken}" "${headItem}" "${rest}"
            RESULT="${RESULT}"
            ;;
        SpecialForm) # Lookup the identifier in the environment and return it's value
            evaluator::call_specialForm "${envToken}" "${headItem}" "${rest}"
            RESULT="${RESULT}"
            ;;
        Lambda)
            evaluator::call_lambda "${envToken}" "${headItem}" "${rest}"
            RESULT="${RESULT}"
            ;;
        Macro)
            stderr "evaluator::eval_list / evaluator::eval_list <macro> not implemented yet"
            exit 1
            ;;
        *)
            stderr "evaluator::eval_list / type [${headType}] not valid"
            exit 1
            ;;
    esac
}


function evaluator::call_builtinFunction() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_builtinFunction(${#@}) ${@}" ; fi

    declare env="${1}"
    declare functionToken="${2}"
    declare argsToken="${3}"

    variable::value "${functionToken}" ; declare functionName="${RESULT}"
    if ! functionExists $functionName; then
        stderr "The builtin function [${functionName}] does not exist"
        exit 1
    fi
    eval "${functionName}" "${env}" "${functionName}" "${argsToken}"
    RESULT=$RESULT
}

function evaluator::call_lambda() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_lambda ${@}" ; fi

    declare env="${1}"
    declare lambdaToken="${2}"
    declare argsToken="${3}"

    variable::LinkedList::new ; declare passedArgs="${RESULT}"

    while ! variable::LinkedList::isEmpty_c "${argsToken}"; do
        variable::LinkedList::first "${argsToken}"
        evaluator::eval "${env}" "${RESULT}"
        variable::LinkedList::append $passedArgs "${RESULT}"
        variable::LinkedList::rest "${argsToken}"; argsToken="${RESULT}"
    done

    variable::Lambda::call $lambdaToken $passedArgs
    RESULT="${RESULT}"
}

function evaluator::call_builtinMacro() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_builtinMacro ${@}" ; fi

    variable::set ${EVALUATOR_VARIABLE} nil nil

    declare env="${1}"
    declare identifier="${2}"
    declare -a values=(${3})

    case "${identifier}" in
        "if")
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in 'if'" ; fi
            stderr "[if] not implemented yet"
            ;;
        *)
            stderr "evaluator::call_identifier / Not implemented [${identifier}]"
            ;;
    esac
}

function evaluator::call_specialForm() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_specialForm(${#@}) ${@}" ; fi

    declare env="${1}"
    declare functionToken="${2}"
    declare argsToken="${3}"

    variable::value "${functionToken}" ; declare functionName="${RESULT}"
    if ! functionExists $functionName; then
        stderr "The builtin function [${functionName}] does not exist"
        exit 1
    fi
    eval "${functionName}" "${env}" "${functionName}" "${argsToken}"
    RESULT="${RESULT}"
}


function evaluator::setup_builtin() {
    declare env="${1}"
    declare type="${2}"
    declare identifier="${3}"
    declare functionName="${4}"

    variable::new "${type}" "${functionName}"
    declare t1="${RESULT}"

    variable::new String "${identifier}"
    declare t2="${RESULT}"

    environment::setVariable "${env}" "${t2}" "${t1}"
}

function evaluator::setup_builtins() {
    declare env="${1}"

    evaluator::setup_builtin "${env}" BuiltinFunction "+" "evaluator::functions::builtin::add"
    evaluator::setup_builtin "${env}" BuiltinFunction "-" "evaluator::functions::builtin::subtract" 
    evaluator::setup_builtin "${env}" BuiltinFunction "*" "evaluator::functions::builtin::multiply" 
    evaluator::setup_builtin "${env}" BuiltinFunction "/" "evaluator::functions::builtin::divide"
    evaluator::setup_builtin "${env}" BuiltinFunction "=" "evaluator::functions::builtin::equals"
    evaluator::setup_builtin "${env}" BuiltinFunction "<" "evaluator::functions::builtin::lessthan"
    evaluator::setup_builtin "${env}" BuiltinFunction ">" "evaluator::functions::builtin::greaterthan"
    evaluator::setup_builtin "${env}" BuiltinFunction "<=" "evaluator::functions::builtin::lessthanorequal"
    evaluator::setup_builtin "${env}" BuiltinFunction ">=" "evaluator::functions::builtin::greaterthanorequal"

    evaluator::setup_builtin "${env}" SpecialForm "if" "evaluator::specialforms::if"
    evaluator::setup_builtin "${env}" SpecialForm "lambda" "evaluator::specialforms::lambda"
    evaluator::setup_builtin "${env}" SpecialForm "let" "evaluator::specialforms::let"
    evaluator::setup_builtin "${env}" SpecialForm 'let*' "evaluator::specialforms::letstar"

    environment::pushScope "${env}"
}


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

# Atom, return the value
createTestEnv ; env="${RESULT}"
variable::new Boolean true ; valueToken="${RESULT}"
evaluator::eval "${env}" $valueToken
variable::debug "${RESULT}" ; \
    assert::equals "Boolean :: true" "${RESULT}" "atom/boolean"

#
# Identifier/Variable
#
createTestEnv ; env="${RESULT}"
setInEnv "${env}" v Integer 4 ; token="${RESULT}"
evaluator::eval "${env}" "${token}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 4" "${RESULT}" "identifier evaluation"

    
# +
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; vCode="${RESULT}"
appendToList $vCode Identifier '+' Integer 5 Integer 2
evaluator::eval "${env}" $vCode
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 7" "${RESULT}" "(+ 5 2)"

# -
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; vCode="${RESULT}"
appendToList $vCode Identifier '-' Integer 5 Integer 2
evaluator::eval "${env}" $vCode
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 3" "${RESULT}" "(- 5 2)"

# *
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; vCode="${RESULT}"
appendToList $vCode Identifier '*' Integer 5 Integer 2
evaluator::eval "${env}" $vCode
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 10" "${RESULT}" "(* 5 2)"

# /
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; vCode="${RESULT}"
appendToList $vCode Identifier '/' Integer 6 Integer 2
evaluator::eval "${env}" $vCode
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 3" "${RESULT}" "(/ 6 2)"

# = / true
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; vCode="${RESULT}"
appendToList $vCode Identifier '=' Integer 2 Integer 2
evaluator::eval "${env}" $vCode
variable::debug "${RESULT}" ; \
    assert::equals "Boolean :: true" "${RESULT}" "(= 2 2)"

# = / false
createTestEnv ; env="${RESULT}"
variable::LinkedList::new ; vCode="${RESULT}"
appendToList $vCode Identifier '=' Integer 2 Integer 3
evaluator::eval "${env}" $vCode
variable::debug "${RESULT}" ; \
    assert::equals "Boolean :: false" "${RESULT}" "(= 2 3)"

#
# variable as argument
#
createTestEnv ; env="${RESULT}"
setInEnv "${env}" u Integer 4 ; token="${RESULT}"
setInEnv "${env}" v Integer 4 ; token="${RESULT}"
setInEnv "${env}" w Integer 2 ; token="${RESULT}"

# variable as argument / + / first
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '+' Identifier 'v' Integer 2
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 6" "${RESULT}" "(+ <v=4> 2)"

# variable as argument / + / second
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '+' Integer 2 Identifier 'v'
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 6" "${RESULT}" "(+ 2 <v=4>)"

# variable as argument / - / first
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '-' Identifier 'v' Integer 2
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 2" "${RESULT}" "(- <v=4> 2)"

# variable as argument / - / second
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '-' Integer 2 Identifier 'v'
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: -2" "${RESULT}" "(- 2 <v=4>)"

# variable as argument / * / first
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '*' Identifier 'v' Integer 2
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 8" "${RESULT}" "(* <v=4> 2)"

# variable as argument / * / second
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '*' Integer 2 Identifier 'v'
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 8" "${RESULT}" "(* 2 <v=4>)"

# variable as argument / / / first
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '/' Identifier 'v' Integer 2
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 2" "${RESULT}" "(/ <v=4> 2)"

# variable as argument / + / second
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '/' Integer 12 Identifier 'v'
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 3" "${RESULT}" "(/ 12 <v=4>)"

# variable as argument / = / first
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '=' Identifier 'v' Integer 2
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Boolean :: false" "${RESULT}" "(= <v=4> 2)"

# variable as argument / + / second
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '=' Integer 4 Identifier 'v'
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Boolean :: true" "${RESULT}" "(= 4 <v=4>)"

#
# Sub expressions
#
createTestEnv ; env="${RESULT}"
setInEnv "${env}" u Integer 4 ; token="${RESULT}"
setInEnv "${env}" v Integer 4 ; token="${RESULT}"
setInEnv "${env}" w Integer 2 ; token="${RESULT}"

variable::new LinkedList ; slistOne=${RESULT}
appendToList $slistOne Identifier + Integer 4 Identifier v
variable::new LinkedList ; slistTwo=${RESULT}
appendToList $slistTwo Identifier - Integer 4 Identifier w
variable::new LinkedList ; vCode=${RESULT}
appendToList $vCode Identifier '*'
variable::LinkedList::append $vCode $slistTwo
variable::LinkedList::append $vCode $slistOne
evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 16" "${RESULT}" "(* (+ 4 <v=4>) (- 4 <w=2>))"

#
# lambda
#
createTestEnv ; lambdaEnv="${RESULT}"
setInEnv $lambdaEnv "y" Integer 10
variable::LinkedList::new ; lambdaArgs="${RESULT}"
appendToList $lambdaArgs Identifier "x"
variable::LinkedList::new ; lambdaExpression="${RESULT}"
appendToList $lambdaExpression Identifier '*' Identifier "x" Identifier "y"
variable::LinkedList::new ; lambdaCode="${RESULT}"
variable::LinkedList::append $lambdaCode $lambdaExpression
variable::Lambda::new "$lambdaEnv $lambdaArgs $lambdaCode" ; lambda="${RESULT}"

createTestEnv ; env=${RESULT}
setInEnv "${env}" "a" Integer 5

variable::new LinkedList ; vCode=${RESULT}
variable::LinkedList::append $vCode $lambda
appendToList $vCode Identifier "a"

evaluator::eval "${env}" "${vCode}"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 50" "${RESULT}" "env(a=5) ((lambda[env(y=10)] (x) (* y x)) a)"

#variable::printMetadata
#echo "typeof ${vCode}=$(variable::type_p $vCode)"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

