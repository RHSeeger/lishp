#!/bin/bash

declare LOGGER_FILE="logfile.txt"
echo > "${LOGGER_FILE}"

function log() {
    echo "${@}" >> "${LOGGER_FILE}"
}

