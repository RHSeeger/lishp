#!/bin/bash

# If this file has already been sourced, just return
[ ${LISHP_SH+true} ] && return
declare -g LISHP_SH=true

. common.sh
. variables.sh
. variables.arraylist.sh
. variables.atom.sh
. variables.linkedlist.sh
. variables.map.sh
. variables.queue.sh
. variables.stack.sh
. callable.sh
. callable.lambda.sh
. environment.sh
. evaluator.sh
. evaluator.functions.builtin.sh
. parser.sh
. logger.sh
. specialforms.sh
. specialforms.if.sh
. specialforms.lambda.sh

echo "Sourced libraries!"

# (lambda (x y)
#     (+ x y)

# per: http://stackoverflow.com/questions/6980090/bash-read-from-file-or-stdin
# This will read from the filename specified as a parameter...
# or from stdin if none specified

# while read line
# do
#   echo "$line"
# done < "${1:-/proc/${$}/fd/0}"

IFS= read var << EOF
((lambda (x y) 
         (+ x y))
  5 10)
EOF
var="((lambda (x y) (+ x y)) 5 10)"
echo "Code read!"
echo =================
echo $var
echo =================

if ! parser::parse "${var}"; then
    echo "Could not parse input
====
${var}
===="
    exit 1
fi
echo "Parsed!"
#variable::printMetadata 
#variable::toSexp "${PARSER_PARSED}" ; echo ${RESULT}
#variable::debug "${PARSER_PARSED}" ; echo ${RESULT}

environment::new ; declare env=${RESULT}
evaluator::setup_builtins "${env}"
echo "Environment setup!"

evaluator::eval ${env} ${PARSER_PARSED}
variable::debug ${RESULT}
echo "Done!"
echo =================
echo $RESULT
echo =================
