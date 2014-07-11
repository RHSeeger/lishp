#!/bin/bash

. common.sh
. variables.sh

if [ -z "${EVALUATOR_VARIABLE}" ]; then
    declare EVALUATOR_VARIABLE="EVAL_RESULT"
    variable::new -name "${EVALUATOR_VARIABLE}" nil nil

    declare EVALUATOR_DEBUG=0
fi

function evaluator::eval() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval ${@}" ; fi

    declare token=$1
    variable::set ${EVALUATOR_VARIABLE} nil nil

    variable::type ${token} ; declare type="${RESULT}"
    case ${type} in
        list)
            evaluator::eval_list "$token"
            ;;
        integer)
            variable::value ${token}
            variable::set ${EVALUATOR_VARIABLE} "${type}" "$RESULT"
            return
            ;;
        string)
            variable::value ${token}
            variable::set ${EVALUATOR_VARIABLE} "${type}" "$RESULT"
            return
            ;;
        identifier) # Lookup the identifier in the environment and return it's value
            stderr "evaluator::eval / Identifier lookup not implemented yet"
            exit 1
            ;;
        *)
            stderr "evaluator::eval / Unknown type [${type}] for [${token}]"
            variable::printMetadata
            exit 1
            ;;
    esac
    
    variable::clone "${EVALUATOR_VARIABLE}"
    #variable::new "$(variable::type_p ${EVALUATOR_VARIABLE})" "$(variable::value_p ${EVALUATOR_VARIABLE})"
}

function evaluator::eval_list() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval_list ${@}" ; fi

    declare token=$1
    variable::set ${EVALUATOR_VARIABLE} nil nil

    variable::type "$token"
    if [ "${RESULT}" != "list" ]; then
        stderr "evaluator::list / must be a list"
        exit 1
    fi

    variable::list::length "${token}"
    if [ "${RESULT}" -eq 0 ]; then 
        variable::set ${EVALUATOR_VARIABLE} nil nil
        return
    fi

    variable::value $token ;      declare -a value=($RESULT)
    variable::type ${value[0]} ;  declare type_1="${RESULT}"
    variable::value ${value[0]} ; declare value_1="${RESULT}"
    variable::list::rest $token ; declare -a args=(${RESULT})

    case "${type_1}" in
        identifier) # Lookup the identifier in the environment and return it's value
            evaluator::call_identifier "${value_1}" "${args[@]}"
            ;;
        lambda)
            stderr "evaluator::eval_list / evaluator::eval_list <lambda> not implemented yet"
            exit 1
            ;;
        *)
            stderr "evaluator::eval_list / type [${type}] not valid"
            exit 1
            ;;
    esac
    
}

function evaluator::call_identifier() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier ${@}" ; fi

    variable::set ${EVALUATOR_VARIABLE} nil nil

    declare identifier=$1
    declare -a values=(${@:2})
#    echo "called [${identifier}] on [${values[@]}]"
#    variable::printMetadata

    case "${identifier}" in
        +)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in +" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} + ${value_2} ))"
            ;;
        a)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in *" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} * ${value_2} ))"
            ;;
        -)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in -" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} - ${value_2} ))"
            ;;
        /)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in /" ; fi
            variable::value ${values[0]} ; declare value_1="${RESULT}"
            variable::value ${values[1]} ; declare value_2="${RESULT}"
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} / ${value_2} ))"
            ;;
        "if")
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in 'if'" ; fi
            stderr "[if] not implemented yet"
            ;;
        *)
            stderr "evaluator::call_identifier / Not implemented [${identifier}]"
            ;;
    esac
}





# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

variable::new list ; vCode=${RESULT}
variable::new identifier '+' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
evaluator::eval $vCode
variable::value ${RESULT} ; \
    assert::equals 7 "$RESULT" '+ 5 2'
#variable::printMetadata

variable::new list ; vCode=${RESULT}
variable::new identifier '-' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval $vCode
variable::value ${RESULT} ; \
    assert::equals 3 "$RESULT" '- 5 2'

variable::new list ; vCode=${RESULT}
variable::new identifier 'a' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval $vCode
variable::value ${RESULT} ; \
    assert::equals 10 "$RESULT" '* 5 2'

variable::new list ; vCode=${RESULT}
variable::new identifier '/' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval $vCode
variable::value ${RESULT} ; \
    assert::equals 2 "$RESULT" '/ 5 2'

#variable::printMetadata
#echo "typeof ${vCode}=$(variable::type_p $vCode)"

assert::report

if [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

