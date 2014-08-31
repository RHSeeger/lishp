#!/bin/bash

# If this file has already been sourced, just return
[ ${PARSER_SH+true} ] && return
declare -g PARSER_SH=true

. common.sh

declare -g PARSER_DEBUG=1
declare -g RESULT
declare -g RESULT_LENGTH

function parser::parse() {
    parser::parse::substring "${@}"
}

function parser::parse::substring() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"

    if parser::parse::integer "${text}" "${offset}"; then
        RESULT=$RESULT
        return 0
    fi

    stderr "Unable to parse string at position ${offset}:
${text:${offset}}"
    exit 1
}

declare PARSER_INTEGER_REGEX='\(0\|\([1-9][0-9]*\)\)'
function parser::parse::integer() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::integer ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"
    if expr match "${subtext}" $PARSER_INTEGER_REGEX; then
        value=$(expr match "${subtext}" $PARSER_INTEGER_REGEX)
        variable::new Integer "${value}" ; RESULT="${RESULT}"
        RESULT_LENGTH=$(expr length "${RESULT}")
        return 0
    fi

    return 1
}


# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

. test.sh

#
# Integer
#
parser::parse "1"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 1" "${RESULT}" "parse 1"




assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

