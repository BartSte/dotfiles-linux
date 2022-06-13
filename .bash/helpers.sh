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

function install_polybar_collections() {
    git clone https://github.com/BartSte/polybar-collection ~/polybar-collection
    git switch develop
    git pull
    cp ~/polybar-collection/fonts ~/.fonts
    cd ~/.fonts
    fc-cache -fv
    ~
}
