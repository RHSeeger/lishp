#!/bin/bash


# If this file has already been sourced, just return
[ ${LOGGER_SH+true} ] && return
declare -g LOGGER_SH=true

. ${BASH_SOURCE%/*}/common.sh

declare -g LOGGER_FILE="logfile.txt"
echo > "${LOGGER_FILE}"

function log() {
    echo "${@}" >> "${LOGGER_FILE}"
}

