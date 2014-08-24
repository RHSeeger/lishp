#!/bin/bash

# If this file has already been sourced, just return
[ ${CALLABLE_SH+true} ] && return
declare -g CALLABLE_SH=true

. common.sh
. variables.sh

variable::type::define Callable
variable::type::define Function Callable
variable::type::define BuiltinFunction Function
variable::type::define Macro Callable
variable::type::define BuiltinMacro Macro


