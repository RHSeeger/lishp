#!/bin/bash

. common.sh
require variables
require environment
provide evaluator

if [ -z "${EVALUATOR_VARIABLE}" ]; then
    declare -g EVALUATOR_VARIABLE="EVAL_RESULT"
    variable::new -name "${EVALUATOR_VARIABLE}" nil nil

    declare -g EVALUATOR_DEBUG=0
fi

#
# eval <env token> <expr token>
#
function evaluator::eval() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval ${@}" ; fi

    declare envToken="${1}"
    declare exprToken="${2}"

    variable::set ${EVALUATOR_VARIABLE} nil nil

    variable::type ${exprToken} ; declare type="${RESULT}"
    case "${type}" in
        list)
            evaluator::eval_sexp "$envToken" "$exprToken"
            ;;
        integer)
            variable::value "$exprToken"
            variable::set ${EVALUATOR_VARIABLE} "${type}" "$RESULT"
            ;;
        string)
            variable::value "$exprToken"
            variable::set ${EVALUATOR_VARIABLE} "${type}" "$RESULT"
            ;;
        identifier) # Lookup the identifier in the environment and return it's value
            variable::value "${exprToken}" ; \
                declare identifierName="${RESULT}"
            environment::lookup "${envToken}" "${identifierName}"
                declare identifierValueToken="${RESULT}"
            variable::type ${identifierValueToken} ; declare type=${RESULT}
            variable::value ${identifierValueToken} ; declare value=${RESULT}
            variable::set ${EVALUATOR_VARIABLE} "${type}" "${value}"
            ;;
        *)
            stderr "evaluator::eval / Unknown type [${type}] for [${exprToken}]"
            variable::printMetadata
            exit 1
            ;;
    esac
    
    variable::clone "${EVALUATOR_VARIABLE}"
}

function evaluator::eval_sexp() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval_sexp ${@}" ; fi

    declare envToken="${1}"
    declare sexpToken="${2}"

    variable::set ${EVALUATOR_VARIABLE} nil nil

    variable::type "$sexpToken"
    if [ "${RESULT}" != "list" ]; then
        stderr "evaluator::eval_sexp / must be a list"
        exit 1
    fi

    variable::list::length "${sexpToken}"
    if [ "${RESULT}" -eq 0 ]; then 
        variable::set ${EVALUATOR_VARIABLE} nil nil
        return
    fi

    variable::value $sexpToken ;      declare -a elements=($RESULT)

    evaluator::eval "${envToken}" "${elements[0]}" ; declare item_1="${RESULT}"
    variable::type "${item_1}" ; declare type_1="${RESULT}"
    variable::value "${item_1}" ; declare value_1="${RESULT}"

    variable::list::rest $sexpToken ; declare -a rest=(${RESULT})

    case "${type_1}" in
        builtinFunction) # Lookup the identifier in the environment and return it's value
            declare -a args=()
            declare -i size
            declare -i max_index
            declare -i i
            (( size=${#rest[@]}, max_index=size-1 ))
            for ((i=0; i<=max_index; i=i+1)); do
                evaluator::eval "${envToken}" "${rest[$i]}"
                args+=("${RESULT}")
            done
            evaluator::call_builtinFunction "${envToken}" "${value_1}" "${args[*]}"
            ;;
        builtinMacro) # Lookup the identifier in the environment and return it's value
            evaluator::call_builtinMacro "${envToken}" "${value_1}" "${rest[@]}"
            ;;
        lambda)
            stderr "evaluator::eval_sexp / evaluator::eval_sexp <lambda> not implemented yet"
            exit 1
            ;;
        macro)
            stderr "evaluator::eval_sexp / evaluator::eval_sexp <macro> not implemented yet"
            exit 1
            ;;
        *)
            stderr "evaluator::eval_sexp / type [${type}] not valid"
            exit 1
            ;;
    esac
    
}

function evaluator::call_identifier() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier ${@}" ; fi

    variable::set ${EVALUATOR_VARIABLE} nil nil

    declare env="${1}"
    declare identifier="${2}"
    declare -a values=(${3})

    case "${identifier}" in
        *)
            stderr "evaluator::call_identifier / Not implemented [${identifier}]"
            ;;
    esac
}

function evaluator::call_builtinFunction() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_builtinFunction(${#@}) ${@}" ; fi

    variable::set ${EVALUATOR_VARIABLE} nil nil

    declare env="${1}"
    declare identifier="${2}"
    declare -a values=(${3})
    case "${identifier}" in
        add)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in +" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} + ${value_2} ))"
            ;;
        multiply)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in *" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} * ${value_2} ))"
            ;;
        subtract)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in -" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} - ${value_2} ))"
            ;;
        divide)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in /" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} / ${value_2} ))"
            ;;
        equals)
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in /" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            if (( "${value_1}" == "${value_2}" )) ; then
                variable::set ${EVALUATOR_VARIABLE} boolean true
            else
                variable::set ${EVALUATOR_VARIABLE} boolean false
            fi
            ;;
        *)
            stderr "evaluator::call_identifier / Not implemented [${identifier}]"
            ;;
    esac
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


function evaluator::setup_builtins() {
    declare env="${1}"

    variable::new builtinFunction "add" ; environment::setVariable "${env}" "+" "${RESULT}"
    variable::new builtinFunction "subtract" ; environment::setVariable "${env}" "-" "${RESULT}"
    variable::new builtinFunction "multiply" ; environment::setVariable "${env}" "*" "${RESULT}"
    variable::new builtinFunction "divide" ; environment::setVariable "${env}" "/" "${RESULT}"
    variable::new builtinFunction "equals" ; environment::setVariable "${env}" "=" "${RESULT}"

    variable::new builtinMacro "if" ; environment::setVariable "${env}" "if" "${RESULT}"

    environment::pushScope "${env}"
}


# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

environment::new ; emptyEnv="${RESULT}"
evaluator::setup_builtins "${emptyEnv}"

# +
variable::new list ; vCode=${RESULT}
variable::new identifier '+' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
evaluator::eval "${emptyEnv}" $vCode
variable::value ${RESULT} ; \
    assert::equals 7 "$RESULT" '+ 5 2'

# -
variable::new list ; vCode=${RESULT}
variable::new identifier '-' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval "${emptyEnv}" $vCode
variable::value ${RESULT} ; \
    assert::equals 3 "$RESULT" '- 5 2'

# *
variable::new list ; vCode=${RESULT}
variable::new identifier '*' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval "${emptyEnv}" $vCode
variable::value ${RESULT} ; \
    assert::equals 10 "$RESULT" '* 5 2'

# /
variable::new list ; vCode=${RESULT}
variable::new identifier '/' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval "${emptyEnv}" $vCode
variable::value ${RESULT} ; \
    assert::equals 2 "$RESULT" '/ 5 2'

# =
# = false
variable::new list ; vCode=${RESULT}
variable::new identifier '=' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval "${emptyEnv}" $vCode
variable::value ${RESULT} ; \
    assert::equals false "$RESULT" '= 5 2 -> false'
# = true
variable::new list ; vCode=${RESULT}
variable::new identifier '=' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 3 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 3 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval "${emptyEnv}" $vCode
variable::value ${RESULT} ; \
    assert::equals true "$RESULT" '= 3 3 -> true'

# variable
environment::new ; env=${RESULT}
variable::new integer 4 ; environment::setVariable $env "v" "${RESULT}"
variable::new identifier "v" ; vCode="${RESULT}"
evaluator::eval "${env}" "${vCode}"
variable::value ${RESULT} ; \
    assert::equals 4 "${RESULT}" "env lookup v=4"

#
# variable as argument
#
environment::new ; env=${RESULT}
evaluator::setup_builtins "${env}"
variable::new integer 4 ; environment::setVariable $env "v" "${RESULT}"

variable::new list ; vCode=${RESULT}
variable::new identifier '+' ; variable::list::append ${vCode} ${RESULT}
variable::new identifier "v" ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
evaluator::eval "${env}" "${vCode}"
variable::value ${RESULT} ; \
    assert::equals 6 "${RESULT}" "env lookup as arguement"


#variable::printMetadata
#echo "typeof ${vCode}=$(variable::type_p $vCode)"

assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

