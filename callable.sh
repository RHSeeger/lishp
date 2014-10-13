#!/bin/bash

# If this file has already been sourced, just return
[ ${CALLABLE_SH+true} ] && return
declare -g CALLABLE_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh
. ${BASH_SOURCE%/*}/variables.linkedlist.sh

variable::type::define Callable
variable::type::define Function Callable
variable::type::define BuiltinFunction Function
variable::type::define Macro Callable


# 
# ======================================================
if [ $0 != $BASH_SOURCE ]; then
    return
fi


# assert::report

if [ ${1+isset} ] && [ "$1" == "debug" ]; then 
    variable::printMetadata
fi

