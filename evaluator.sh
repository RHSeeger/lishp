#!/bin/bash

. common.sh
. variables.sh

if [ -z "${EVALUATOR_TOKEN}" ]; then
    declare EVALUATOR_TOKEN="evalToken"
    declare EVALUATOR_RESULT_TYPE=nil
    declare EVALUATOR_RESULT_VALUE=nil

    declare EVALUATOR_DEBUG=1
fi

function evaluator_eval() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator_eval ${@}" ; fi

    declare token=$1
    EVALUATOR_RESULT_TYPE=nil
    EVALUATOR_RESULT_VALUE=nil

    declare type=$(variable_type_p ${token})
    case ${type} in
        list)
            evaluator_eval_list "$token"
            ;;
        integer)
            EVALUATOR_RESULT_TYPE=$type
            EVALUATOR_RESULT_VALUE=$(variable_value_p ${token})
            return
            ;;
        string)
            EVALUATOR_RESULT_TYPE=$type
            EVALUATOR_RESULT_VALUE=$(variable_value_p ${token})
            return
            ;;
        identifier) # Lookup the identifier in the environment and return it's value
            stderr "evaluator_eval / Identifier lookup not implemented yet"
            exit 1
            ;;
        *)
            stderr "evaluator_eval / Unknown type [${type}] for [${token}]"
            exit 1
            ;;
    esac
}

function evaluator_eval_list() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator_eval_list ${@}" ; fi

    declare token=$1
    EVALUATOR_RESULT_TYPE=nil
    EVALUATOR_RESULT_VALUE=nil

    if [ variable_list_length == 0 ]; then 
        EVALUATOR_RESULT_TYPE=nil
        EVALUATOR_RESULT_VALUE=nil
        return
    fi

    declare item_1_token=$(variable_list_index_p $token 0)
    echo "item_1_token=[${item_1_token}]"

    evaluator_eval $item_1_token ; declare $item_1_value="${RESULT}"
    declare type=${EVALUATOR_RESULT_TYPE}
    declare value=${EVALUATOR_RESULT_VALUE}

    case ${type} in
        list)
            stderr "evaluator_eval_list / evaluator_eval_list <list> not valid"
            exit 1
            ;;
        integer)
            stderr "evaluator_eval_list / evaluator_eval_list <list> not valid"
            exit 1
            ;;
        string)
            stderr "evaluator_eval_list / evaluator_eval_list <string> not valid"
            exit 1
            ;;
        identifier) # Lookup the identifier in the environment and return it's value
            evaluator_call_identifier ${item_1_token}
            ;;
        lambda)
            stderr "evaluator_eval_list / evaluator_eval_list <lambda> not implemented yet"
            exit 1
            ;;
        *)
            stderr "evaluator_eval_list / Unknown type [${type}] for [${token}]"
            exit 1
            ;;
    esac
    
}

function evaluator_call_identifier() {
    if [[ ${EVALUATOR_DEBUG} == 1 ]]; then stderr "evaluator_call_identifier ${@}" ; fi

    declare identifier=$1
    declare -a values=${1:1}
    echo "called ${1} on ${values[@]}"
}





# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

variable_new list ; vCode=${RESULT}
variable_new identifier "+" ; variable_list_append ${vCode} ${RESULT}
variable_new integer 5 ; variable_list_append ${vCode} ${RESULT}
variable_new integer 2 ; variable_list_append ${vCode} ${RESULT}

variable_print_metadata
echo "typeof ${vCode}=$(variable_type_p $vCode)"

evaluator_eval $vCode
assertEquals 7 "${RESULT}" "+ 5 2"
