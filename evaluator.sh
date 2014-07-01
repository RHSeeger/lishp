#!/bin/bash

. common.sh
. variables.sh

if [ -z "${EVALUATOR_TOKEN}" ]; then
    declare EVALUATOR_TOKEN="evalToken"
    variable::new nil nil
    declare EVALUATOR_VARIABLE="${RESULT}"

    declare EVALUATOR_DEBUG=0
fi

function evaluator::eval() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval ${@}" ; fi

    declare token=$1
    variable::set ${EVALUATOR_VARIABLE} nil nil

    declare type=$(variable::type_p ${token})
    case ${type} in
        list)
            evaluator::eval_list "$token"
            ;;
        integer)
            variable::set ${EVALUATOR_VARIABLE} "${type}" "$(variable::value_p ${token})"
            return
            ;;
        string)
            variable::set ${EVALUATOR_VARIABLE} "${type}" "$(variable::value_p ${token})"
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
    
    variable::new "$(variable::type_p ${EVALUATOR_VARIABLE})" "$(variable::value_p ${EVALUATOR_VARIABLE})"
}

function evaluator::eval_list() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::eval_list ${@}" ; fi

    declare token=$1
    variable::set ${EVALUATOR_VARIABLE} nil nil

    if [ $(variable::type_p "$token") != "list" ]; then
        stderr "evaluator::list / must be a list"
        exit 1
    fi

    if [ variable::list::length == 0 ]; then 
        variable::set ${EVALUATOR_VARIABLE} nil nil
        return
    fi

    declare -a value=($(variable::value_p $token))
    declare type_1=$(variable::type_p ${value[0]})
    declare value_1=$(variable::value_p ${value[0]})
    declare -a args=($(variable::list::rest_p $token))

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
            declare value_1=$(variable::value_p ${values[0]})
            declare value_2=$(variable::value_p ${values[1]})
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} + ${value_2} ))"
            ;;
        a)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in *" ; fi
            declare value_1=$(variable::value_p ${values[0]})
            declare value_2=$(variable::value_p ${values[1]})
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} * ${value_2} ))"
            ;;
        -)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in -" ; fi
            declare value_1=$(variable::value_p ${values[0]})
            declare value_2=$(variable::value_p ${values[1]})
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} - ${value_2} ))"
            ;;
        /)
            # TODO: check length and types
            if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator::call_identifier in /" ; fi
            declare value_1=$(variable::value_p ${values[0]})
            declare value_2=$(variable::value_p ${values[1]})
            variable::set ${EVALUATOR_VARIABLE} integer "$(( ${value_1} / ${value_2} ))"
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
assertEquals 7 "$(variable::value_p ${RESULT})" '+ 5 2'
#variable::printMetadata

variable::new list ; vCode=${RESULT}
variable::new identifier '-' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval $vCode
assertEquals 3 "$(variable::value_p ${RESULT})" '- 5 2'

variable::new list ; vCode=${RESULT}
variable::new identifier 'a' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval $vCode
assertEquals 10 "$(variable::value_p ${RESULT})" '* 5 2'

variable::new list ; vCode=${RESULT}
variable::new identifier '/' ; variable::list::append ${vCode} ${RESULT}
variable::new integer 5 ; variable::list::append ${vCode} ${RESULT}
variable::new integer 2 ; variable::list::append ${vCode} ${RESULT}
#variable::printMetadata
evaluator::eval $vCode
assertEquals 2 "$(variable::value_p ${RESULT})" '/ 5 2'

#variable::printMetadata
#echo "typeof ${vCode}=$(variable::type_p $vCode)"

