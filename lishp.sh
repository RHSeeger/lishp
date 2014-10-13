#!/bin/bash

# If this file has already been sourced, just return
[ ${LISHP_SH+true} ] && return
declare -g LISHP_SH=true
declare -g VERBOSE
if [ ${1+isset} ] && [ "$1" == "-verbose" ]; then 
    VERBOSE=true
    shift
else
    VERBOSE=false
fi


. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.arraylist.sh
. ${BASH_SOURCE%/*}/variables.atom.sh
. ${BASH_SOURCE%/*}/variables.linkedlist.sh
. ${BASH_SOURCE%/*}/variables.map.sh
. ${BASH_SOURCE%/*}/variables.queue.sh
. ${BASH_SOURCE%/*}/variables.stack.sh
. ${BASH_SOURCE%/*}/callable.sh
. ${BASH_SOURCE%/*}/callable.lambda.sh
. ${BASH_SOURCE%/*}/environment.sh
. ${BASH_SOURCE%/*}/evaluator.sh
. ${BASH_SOURCE%/*}/evaluator.functions.builtin.sh
. ${BASH_SOURCE%/*}/parser.sh
. ${BASH_SOURCE%/*}/logger.sh
. ${BASH_SOURCE%/*}/specialforms.sh
. ${BASH_SOURCE%/*}/specialforms.if.sh
. ${BASH_SOURCE%/*}/specialforms.lambda.sh
. ${BASH_SOURCE%/*}/specialforms.let.sh
. ${BASH_SOURCE%/*}/specialforms.letstar.sh

$VERBOSE && echo "Sourced libraries!"

# (lambda (x y)
#     (+ x y)

# per: http://stackoverflow.com/questions/6980090/bash-read-from-file-or-stdin
# This will read from the filename specified as a parameter...
# or from stdin if none specified

read -r -d '' code < "${1:-/proc/${$}/fd/0}"

$VERBOSE && echo "Code read!"
$VERBOSE && echo =================
$VERBOSE && echo "$code"
$VERBOSE && echo =================

if ! parser::parse::multiExpression "${code}"; then
    echo "Could not parse input
====
${code}
===="
    exit 1
fi
$VERBOSE && echo "Parsed!"
#variable::printMetadata 
#variable::toSexp "${PARSER_PARSED}" ; echo ${RESULT}
#variable::debug "${PARSER_PARSED}" ; echo ${RESULT}

environment::new ; declare env=${RESULT}
evaluator::setup_builtins "${env}"
$VERBOSE && echo "Environment setup!"

evaluator::evalFromLinkedList ${env} ${PARSER_PARSED}
variable::debug ${RESULT}
$VERBOSE && echo "Done!"
$VERBOSE && echo =================
echo "$RESULT"
$VERBOSE && echo =================
