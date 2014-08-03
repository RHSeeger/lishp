#!/bin/bash

. common.sh
provide logger

declare -g LOGGER_FILE="logfile.txt"
echo > "${LOGGER_FILE}"

function log() {
    echo "${@}" >> "${LOGGER_FILE}"
}

