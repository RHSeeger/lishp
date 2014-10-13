#!/bin/bash

# If this file has already been sourced, just return
[ ${PARSER_SH+true} ] && return
declare -g PARSER_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.linkedlist.sh

declare -g PARSER_DEBUG=0
declare -g PARSER_PARSED
declare -g PARSER_PARSED_COUNT

function parser::parse() {
    parser::parse::substring "${@}"
}

#
# Parses a series of expressions, effectively what you would find inside an sexp.
# ?whitespace? ?expression? ?whitespace expression? ... ?whitespace expression? ?whitespace?
#
function parser::parse::multiExpression() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare originalOffset="${2-0}"
    declare offset=$originalOffset

    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse multiExpr from:
${text:${offset}}" ; fi

    # (
    #     w? )
    #     w? p 
    #            w? )
    #            w p
    #                 w? )
    #                 w p

    # Parse a list of items
    variable::LinkedList::new ; declare items="${RESULT}"

    # Prune any beginning whitespace
    if parser::parse::whitespace "$text" ${offset}; then
        (( offset += ${PARSER_PARSED_COUNT} ))
    fi

    # first item in list
    if parser::parse "${text}" ${offset}; then
        variable::LinkedList::append "$items" ${PARSER_PARSED}
        (( offset += ${PARSER_PARSED_COUNT} ))
    else
        # No items found, an empty list
        PARSER_PARSED="${items}"
        (( PARSER_PARSED_COUNT = offset - originalOffset ))
        return 0
    fi

    # Parse instances of 
    #    <whitespace> + <expression>
    while true; do
        if ! parser::parse::whitespace "$text" ${offset}; then
            # No whitespace found, we're done
            PARSER_PARSED="${items}"
            (( PARSER_PARSED_COUNT = offset - originalOffset ))
            return 0
        fi
        (( offset += ${PARSER_PARSED_COUNT} )) ; # increment by amount eatten by whitespace parser

        if ! parser::parse "${text}" ${offset}; then
            # No expression found, we're done
            PARSER_PARSED="${items}"
            (( PARSER_PARSED_COUNT = offset - originalOffset ))
            return 0
        fi
        variable::LinkedList::append "$items" "${PARSER_PARSED}" # Add item found to items list
        (( offset += ${PARSER_PARSED_COUNT} )) ; # increment by amount eatten by whitespace parser
    done

    stderr "Should never get here"
    exit 1
}

function parser::parse::substring() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"

    if parser::parse::atom "${text}" "${offset}"; then
        #echo "Parsed atom substring [length=${PARSER_PARSED_COUNT}] at [${text:${offset}}]"
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::sexp "${text}" "${offset}"; then
        #echo "Parsed sexp substring [length=${PARSER_PARSED_COUNT}] at [${text:${offset}}]"
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    fi

#    stderr "Unable to parse string at position ${offset}:
#${text:${offset}}"
    return 1
}

function parser::parse::atom() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    if parser::parse::real "${text}" "${offset}"; then
        #echo "Parsed real substring [length=${PARSER_PARSED_COUNT}] at [${text:${offset}}]"
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::integer "${text}" "${offset}"; then
        #echo "Parsed integer substring [length=${PARSER_PARSED_COUNT}] at [${text:${offset}}]"
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::identifier "${text}" "${offset}"; then
        #echo "Parsed identifier substring [length=${PARSER_PARSED_COUNT}] at [${text:${offset}}]"
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    elif parser::parse::string "${text}" "${offset}"; then
        #echo "Parsed string substring [length=${PARSER_PARSED_COUNT}] at [${text:${offset}}]"
        PARSER_PARSED="${PARSER_PARSED}"
        PARSER_PARSED_COUNT="${PARSER_PARSED_COUNT}"
        return 0
    fi
    return 1
}

function parser::parse::real() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse real from:
${text:${offset}}" ; fi
    return 1
}

#
# INTEGER
#
declare -g PARSER_INTEGER_REGEX='\(-\?[1-9][0-9]*\)'
declare -g PARSER_INTEGER_0_REGEX='\(0\)'
function parser::parse::integer() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"

    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse integer from:
${text:${offset}}" ; fi

    declare value ; value=$(expr match "${subtext}" $PARSER_INTEGER_REGEX)
    if [[ $? == 0 ]]; then
        variable::new Integer "${value}"
        PARSER_PARSED="${RESULT}"
        PARSER_PARSED_COUNT="${#value}"
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
declare -g PARSER_IDENTIFIER_REGEX='\([a-zA-Z!?*+<=>_:-][a-zA-Z0-9!?*+<=>_:-]*\)'
function parser::parse::identifier() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"

    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse identifier from:
${subtext}" ; fi

    declare value ; value=$(expr match "${subtext}" $PARSER_IDENTIFIER_REGEX)
    if [[ $? == 0 ]]; then
        variable::new Identifier "${value}"
        PARSER_PARSED="${RESULT}"
        PARSER_PARSED_COUNT="${#value}"
        return 0
    fi

    return 1
}

#
# STRING
#
declare -g PARSER_STRING_REGEX='\([^"]*\)'
function parser::parse::string() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare offset="${2-0}"
    declare subtext="${1:${offset}}"

    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse string from:
${subtext}" ; fi

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
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare originalOffset="${2-0}"
    declare offset=$originalOffset

    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse sexp from:
${text:${offset}}" ; fi

    if [[ "${text:${offset}:1}" != "(" ]]; then
        PARSER_PARSED=""
        PARSER_PARSED_COUNT=0
        return 1
    fi
    (( offset += 1 ))

    # (
    #     w? )
    #     w? p 
    #            w? )
    #            w p
    #                 w? )
    #                 w p

    # Parse a list of items
    variable::LinkedList::new ; declare items="${RESULT}"

    # Prune any beginning whitespace
    if parser::parse::whitespace "$text" ${offset}; then
        (( offset += ${PARSER_PARSED_COUNT} ))
    fi

    # empty list
    if [[ "${text:${offset}:1}" == ")" ]]; then
        (( offset += 1 ))
        PARSER_PARSED=${items}
        (( PARSER_PARSED_COUNT = offset - originalOffset ))
        return 0
    fi

    # first item in list
    if parser::parse "${text}" ${offset}; then
        variable::LinkedList::append "$items" ${PARSER_PARSED}
        (( offset += ${PARSER_PARSED_COUNT} ))
    fi

    # From now on every item is either
    #    <no whitespace> + <closing paren>
    #    <whitespace> + <closing paren>
    #    <whitespace> + <something parsed>
    while true; do
        if parser::parse::whitespace "$text" ${offset}; then # can be close paren or parsed
            (( offset += ${PARSER_PARSED_COUNT} ))
            if [[ "${text:${offset}:1}" == ")" ]]; then
                (( offset += 1 ))
                PARSER_PARSED=${items}
                (( PARSER_PARSED_COUNT = offset - originalOffset ))
                return 0
            elif parser::parse "${text}" ${offset}; then
                variable::LinkedList::append "$items" "${PARSER_PARSED}"
                (( offset += ${PARSER_PARSED_COUNT} ))
            else
                PARSER_PARSED=""
                PARSER_PARSED_COUNT=0
                return 1
            fi                
        else # can only be close paren
            if [[ "${text:${offset}:1}" == ")" ]]; then
                (( offset += 1 ))
                PARSER_PARSED=${items}
                (( PARSER_PARSED_COUNT = offset - originalOffset ))
                return 0
            else 
                PARSER_PARSED=""
                PARSER_PARSED_COUNT=0
                return 1
            fi
        fi
    done

    stderr "Should never get here"
    exit 1
}

#
# WHITESPACE
# 
declare -g PARSER_WHITESPACE_REGEX='\([ 	
][ 	
]*\)'
function parser::parse::whitespace() {
    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "${FUNCNAME} ${@}" ; fi

    declare text="${1}"
    declare originalOffset="${2-0}"

    if [[ ${PARSER_DEBUG} == 1 ]]; then stderr "Trying to parse whitespace from:
${text:${originalOffset}}" ; fi

    declare offset=${originalOffset}
    declare char="${text:${offset}:1}"
    declare parsed=""

    while [[ $char == " " || $char == "	" || $char == "
" ]]; do
        (( offset += 1 ))
        parsed+="${char}"
        char="${text:${offset}:1}"
    done

    if [[ $offset -gt $originalOffset ]]; then
        PARSER_PARSED="${parsed}"
        (( PARSER_PARSED_COUNT = offset - originalOffset ))
        return 0
    else
        PARSER_PARSED=""
        PARSER_PARSED_COUNT=0
        return 1
    fi
}


# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi

. ${BASH_SOURCE%/*}/test.sh

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

parser::parse::whitespace 'abc def' ; \
    assert::equals 1 $? "match non-whitespace / code"

parser::parse::whitespace '' ; \
    assert::equals 1 $? "match empty non-whitespace / code"

parser::parse::whitespace ')' ; \
    assert::equals 1 $? "match close paren against whitespace / code"

#
# Multi-Expr
#
TEST="multiExpression - single expr"
parser::parse::multiExpression "a" ; assert::equals 0 $? "${TEST} / code"
assert::equals 1 ${PARSER_PARSED_COUNT} "${TEST} / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "${TEST} / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 1 ${RESULT} "${TEST} / length"
variable::LinkedList::first ${PARSER_PARSED} ; \
    variable::value ${RESULT} ; \
    assert::equals "a" "${RESULT}" "${TEST} / value"

TEST="multiExpression - multiple expressions"
parser::parse::multiExpression "a b" ; assert::equals 0 $? "${TEST} / code"
assert::equals 3 ${PARSER_PARSED_COUNT} "${TEST} / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "${TEST} / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 2 ${RESULT} "${TEST} / length"

TEST="multiExpression - whitespaces"
parser::parse::multiExpression " b " ; assert::equals 0 $? "${TEST} / code"
assert::equals 3 ${PARSER_PARSED_COUNT} "${TEST} / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "${TEST} / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 1 ${RESULT} "${TEST} / length"

TEST="multiExpression - integer"
parser::parse::multiExpression "1" ; assert::equals 0 $? "${TEST} / code"
assert::equals 1 ${PARSER_PARSED_COUNT} "${TEST} / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "${TEST} / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 1 ${RESULT} "${TEST} / length"

TEST="multiExpression - sexp"
parser::parse::multiExpression "(a)" ; assert::equals 0 $? "${TEST} / code"
assert::equals 3 ${PARSER_PARSED_COUNT} "${TEST} / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "${TEST} / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 1 ${RESULT} "${TEST} / length"

TEST="multiExpression - sexps"
parser::parse::multiExpression "(a) (b)" ; assert::equals 0 $? "${TEST} / code"
assert::equals 7 ${PARSER_PARSED_COUNT} "${TEST} / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "${TEST} / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 2 ${RESULT} "${TEST} / length"

#
# SEXP
#
parser::parse "()" ; assert::equals 0 $? "match empty sexp / code"
assert::equals 2 ${PARSER_PARSED_COUNT} "match empty sexp / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "match empty sexp / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 0 ${RESULT} "match empty sexp / length"

parser::parse "( )" ; assert::equals 0 $? "match almost empty sexp / code"
assert::equals 3 ${PARSER_PARSED_COUNT} "match almost empty sexp / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "match almost empty sexp / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 0 ${RESULT} "match almost empty sexp / length"

parser::parse "(a)" ; assert::equals 0 $? "single element sexp / code"
assert::equals 3 ${PARSER_PARSED_COUNT} "single element sexp / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "single element sexp / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 1 ${RESULT} "single element sexp / length"

parser::parse "( a )" ; assert::equals 0 $? "single element sexp / code"
assert::equals 5 ${PARSER_PARSED_COUNT} "single element sexp / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "single element sexp / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 1 ${RESULT} "single element sexp / length"

parser::parse "(a b)" ; assert::equals 0 $? "two element sexp / code"
assert::equals 5 ${PARSER_PARSED_COUNT} "two element sexp / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "two element sexp / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 2 ${RESULT} "two element sexp / length"

parser::parse "((a) (b) c)" ; assert::equals 0 $? "nested element sexp / code"
assert::equals 11 ${PARSER_PARSED_COUNT} "nested element sexp / count"
variable::type ${PARSER_PARSED} ; assert::equals "LinkedList" ${RESULT} "nested element sexp / type"
variable::LinkedList::length ${PARSER_PARSED} ; assert::equals 3 ${RESULT} "nested element sexp / length"

assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

