#!/usr/bin/env bash

usage="Usage: $0 <message> [-h | --help]

Source this file to use the log function. The log function has the following
usage:

    log [-v | --verbose] <message>

Together with the following variables:

- OPEN_LOG_FILE: Logging is always done to verbose.
- OPEN_LOG_LEVEL: If set to 'verbose' also messages that are logged with the -v
    or --verbose option are logged to stderr and the file.
- OPEN_LOG_LEVEL: If set to 'quiet' all messages are suppressed.

Options:
    -h, --help      Show this message and exit."

if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "$usage"
    exit 0
fi

################################################################################
# If the OPEN_LOG_FILE is set, always log to it.
# If verbose is true, only log to stderr if OPEN_LOG_LEVEL is set to 'verbose'.
# If verbose is false, always log to stderr.
################################################################################
log() {
    local verbose=false
    local message=""
    while [[ $# -gt 0 ]]; do
        case $1 in
        -v | --verbose)
            verbose=true
            ;;
        *)
            if [[ -z $message ]]; then
                message=$1
            else
                echo "Unknown option: $1" >&2
                exit 1
            fi
            ;;
        esac
        shift
    done

    if [[ -z $message ]]; then
        message=$(cat)
    fi

    if [[ -z $message ]]; then
        return
    fi

    if [[ -n ${OPEN_LOG_FILE:-} ]]; then
        echo "$message" >>"$OPEN_LOG_FILE"
    fi

    if [[ $verbose == true && ${OPEN_LOG_LEVEL:-""} != "verbose" ]]; then
        return
    fi

    echo "$message" >&2
}

log_clear() {
    if [[ -n ${OPEN_LOG_FILE:-} ]]; then
        echo -n "" >"$OPEN_LOG_FILE"
    fi
}
