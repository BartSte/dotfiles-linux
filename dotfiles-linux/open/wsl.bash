#!/usr/bin/env bash

convert_win_path() {
    local winpath=${1:-$(cat)}
    if $win && running_wsl; then
        wslpath -u $winpath || {
            echo "Failed to convert windows path to wsl path: $winpath" >>$debug
            exit 1
        }
    else
        echo $winpath
    fi
}

