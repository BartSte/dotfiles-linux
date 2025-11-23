#!/usr/bin/env bash
set -euo pipefail

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

################################################################################
# Converts backward slashes (\) to forward slashes (/). For example:
# - \\wsl.localhost\Arch\home
# becomes:
# - //wsl.localhost/Arch/home
###############################################################################
backwards_to_forward_slashes() {
    sed 's,\\,/,g'
}

##############################################################################
# Removes quotations from a string. For example:
# - '\"Hello world\"'
# becomes:
# - Hello world
no_qoutes() {
    sed 's/"//g'
}


