#!/bin/bash

# If this file has already been sourced, just return
[ ${VARIABLES_ATOM_SH+true} ] && return
declare -g VARIABLES_ATOM_SH=true

. ${BASH_SOURCE%/*}/common.sh
. ${BASH_SOURCE%/*}/variables.sh

variable::type::define Nil
variable::type::define Identifier
variable::type::define Atom
variable::type::define Boolean Atom
variable::type::define String Atom
variable::type::define Number Atom
variable::type::define Integer Number
variable::type::define Real Number


function variable::Atom::toSexp() {
    variable::value "${1}"
    RESULT=${RESULT}
}

function variable::Identifier::toSexp() {
    variable::value "${1}"
    RESULT=${RESULT}
}

function variable::Nil::toSexp() {
    RESULT="Nil"
}
