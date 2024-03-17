#!/usr/bin/env bash
set -euo pipefail

running_wsl() {
    grep -iq microsoft /proc/version
}

running_tmux() { [[ -n $TMUX ]]; }

################################################################################
# Checks if a file has a specific extension.
################################################################################
has_ext() {
    local file="$1"
    local ext="${file##*.}"
    [[ $ext == "$2" ]]
}

################################################################################
# Checks if a file has a specific mime type.
################################################################################
has_type() {
    file --mime-type -b "$1" | grep -q "$2"
}

################################################################################
# Checks if a string is a url.
################################################################################
is_url() { [[ $1 =~ ^([a-zA-Z]+://|www\..*) ]]; }