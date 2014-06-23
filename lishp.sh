#!/bin/bash

function stderr() {
    echo "${@}" 2>&1
}

. variables.sh

# (lambda (x y) ; add
#     (+ x y)

variable_new list ; vArgs=${RESULT}
variable_new string "x" ; variable_list_append ${vArgs} ${RESULT}
variable_new string "y" ; variable_list_append ${vArgs} ${RESULT}

variable_new list ; vCode=${RESULT}
variable_new string "+" ; variable_list_append ${vCode} ${RESULT}
variable_new string "x" ; variable_list_append ${vCode} ${RESULT}
variable_new string "y" ; variable_list_append ${vCode} ${RESULT}

variable_new list ; vLambda=${RESULT}
variable_new string "lambda" ; variable_list_append ${vLambda} ${RESULT}
variable_list_append ${vLambda} ${vArgs}
variable_list_append ${vLambda} ${vCode}

variable_print_metadata
echo ========== vArgs
variable_print $vArgs
echo ========== vCode
variable_print $vCode
echo ========== vLambda
variable_print $vLambda
