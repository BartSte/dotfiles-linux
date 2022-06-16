#!/bin/bash

function get_ignored_directories() {
    readarray directories < ~/.ignore
    surround_by_quotes "${directories[@]}"
}

function surround_by_quotes() {
    ignored_directories=()
    for directory_trailing_space in "$@"; do
        directory=${directory_trailing_space::-1}
        ignored_directories+=("-not -path \"${directory}\"")
    done
}

function winenv() {
    cmd.exe /C "echo %$*%" | tr -d '\r'
}

