#!/bin/bash

# If this file has already been sourced, just return
[ ${PARSER_SH+true} ] && return
declare -g PARSER_SH=true

. common.sh

declare -g PARSER_DEBUG=0
declare -g PARSER_PARSED
declare -g PARSER_PARSED_COUNT

function parser::parse() {
    parser::parse::substring "${@}"
}

function parser::parse::substring() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"

    if parser::parse::atom "${text}" "${offset}"; then
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::sexp "${text}" "${offset}"; then
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    fi

    stderr "Unable to parse string at position ${offset}:
${text:${offset}}"
    return 1
}

function parser::parse::atom() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::atom ${@}" ; fi

    if parser::parse::real "${text}" "${offset}"; then
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::integer "${text}" "${offset}"; then
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::identifier "${text}" "${offset}"; then
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::string "${text}" "${offset}"; then
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    fi
    return 1
}

function parser::parse::real() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::real ${@}" ; fi
    return 1
}

#
# INTEGER
#
declare -g PARSER_INTEGER_REGEX='\(-\?[1-9][0-9]*\)'
declare -g PARSER_INTEGER_0_REGEX='\(0\)'
function parser::parse::integer() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::integer ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"

    declare value ; value=$(expr match "${subtext}" $PARSER_INTEGER_REGEX)
    if [[ $? == 0 ]]; then
        variable::new Integer "${value}"
        PARSER_PARSED="${RESULT}"
        PARSER_PARSED_COUNT=$(expr length "${value}")
        return 0
    fi

    if [[ "${subtext:0:1}" == "0" ]]; then
        variable::new Integer "0"
        PARSER_PARSED="${RESULT}"
        PARSER_PARSED_COUNT=1
        return 0
    fi

    return 1
}

#
# Identifier
#
declare -g PARSER_IDENTIFIER_REGEX='\([a-zA-Z][a-zA-Z0-9!?+_-:]*\)'
function parser::parse::identifier() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::identifier ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"
    declare value ; value=$(expr match "${subtext}" $PARSER_IDENTIFIER_REGEX)
    if [[ $? == 0 ]]; then
        variable::new Identifier "${value}"
        PARSER_PARSED="${RESULT}"
        PARSER_PARSED_COUNT=$(expr length "${PARSER_PARSED}")
        return 0
    fi

    return 1
}

#
# STRING
#
declare -g PARSER_STRING_REGEX='\([^"]*\)'
function parser::parse::string() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::string ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"

    if [[ "${subtext:0:1}" != "\"" ]]; then
        return 1
    fi

    declare value ; value=$(expr match "${subtext:1}" $PARSER_STRING_REGEX)
    if [[ $? != 0 ]]; then
        return 1
    fi
    
    # TODO: This should be checking the last value
    declare endIndex
    (( endIndex = 1 + $(expr length "${value}") ))
    if [[ "${subtext:${endIndex}:1}" != "\"" ]]; then
        return 1
    fi

    variable::new String "${value}"
    PARSER_PARSED="${RESULT}"
    (( PARSER_PARSED_COUNT = $(expr length "${value}") + 2 ))

    return 0
}

#
# sexp
#
function parser::parse::sexp() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::sexp ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"

    if [[ "${subtext:0:1}" != "(" ]]; then
        return 1
    fi

    # TODO: Parse a list of items

    if [[ "${subtext:0:1}" != ")" ]]; then
        return 1
    fi

    return 0
}

#
# WHITESPACE
# 
declare -g PARSER_WHITESPACE_REGEX='\([ 	
][ 	
]*\)'
function parser::parse::whitespace() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "parser::parse::whitespace ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"
    declare value ; value=$(expr match "${subtext}" "$PARSER_WHITESPACE_REGEX")
    if [[ $? == 0 ]]; then
        PARSER_PARSED=""
        PARSER_PARSED_COUNT=$(expr length "${value}")
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
parser::parse "1" ; \
    assert::equals 0 $? "parse 1 succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 1" "${RESULT}" "parse 1"
assert::equals 1 "${PARSER_PARSED_COUNT}" "parse 1 / count"

parser::parse "123456" ; \
    assert::equals 0 $? "parse 123456 succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 123456" "${RESULT}" "parse 123456"
assert::equals 6 "${PARSER_PARSED_COUNT}" "parse 123456 / count"

parser::parse "0" ; \
    assert::equals 0 $? "parse 0 succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: 0" "${RESULT}" "parse 0"
assert::equals 1 "${PARSER_PARSED_COUNT}" "parse 0 / count"

parser::parse "-10" ; \
    assert::equals 0 $? "parse -10 succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "Integer :: -10" "${RESULT}" "parse -10"
assert::equals 3 "${PARSER_PARSED_COUNT}" "parse 1 / count"

output=$(parser::parse "-0")
assert::equals 1 $? "parse -0 should fail"

#
# Identifier
#
parser::parse "v" ; \
    assert::equals 0 $? "parse \"abc\" succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "Identifier :: v" "${RESULT}" "parse v"

parser::parse "a?" ; \
    assert::equals 0 $? "parse \"abc\" succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "Identifier :: a?" "${RESULT}" "parse a?"

#
# STRING
#
parser::parse '"abc"' ; \
    assert::equals 0 $? "parse \"abc\" succeeds"
variable::debug "${RESULT}" ; \
    assert::equals "String :: abc" "${RESULT}" "parse \"abc\""
assert::equals 5 "${PARSER_PARSED_COUNT}" "parse \"abc\" / count"

#
# WHITESPACE
#
parser::parse::whitespace ' 	 ' ; \
    assert::equals 0 $? "match whitespace / code"
assert::equals 3 ${PARSER_PARSED_COUNT} "match whitepace / count"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

