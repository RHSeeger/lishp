#!/bin/bash

. common.sh
. variables.sh

# (lambda (x y) ; add
#     (+ x y)

variable::new list ; vArgs=${RESULT}
variable::new string "x" ; variable::list::append ${vArgs} ${RESULT}
variable::new string "y" ; variable::list::append ${vArgs} ${RESULT}

variable::new list ; vCode=${RESULT}
variable::new string "+" ; variable::list::append ${vCode} ${RESULT}
variable::new string "x" ; variable::list::append ${vCode} ${RESULT}
variable::new string "y" ; variable::list::append ${vCode} ${RESULT}

variable::new list ; vLambda=${RESULT}
variable::new string "lambda" ; variable::list::append ${vLambda} ${RESULT}
variable::list::append ${vLambda} ${vArgs}
variable::list::append ${vLambda} ${vCode}

variable::printMetadata
echo ========== vArgs
variable::print $vArgs
echo ========== vCode
variable::print $vCode
echo ========== vLambda
variable::print $vLambda
