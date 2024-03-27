#!/usr/bin/env bash
set -euo pipefail
this_dir=$(dirname "$(readlink -f "$0")")

. "$this_dir"/logger.bash
. "$this_dir"/helpers.bash

open_url() {
    log "Url detected, opening in browser." -v
    if running wsl; then
        log "Opening url with WSLBROWSER: $WSLBROWSER" -v
        "$WSLBROWSER" "$1" 2>&1 | log -v &
    else
        log "Opening url with BROWSER: $BROWSER" -v
        $BROWSER "$1" 2>&1 | log -v &
    fi
}

open_img() {
    log "Opening image $1 with imv" -v
    imv "$1" | log -v &
}

################################################################################
# open_text <path> [-w | --win]
# Opens <path> in vim at line number that may be appended to the path using a :
# separator. For example: /path/to/file:10
#
# If the -w or --win option is used, the path is converted to a wsl path if wsl
# is running.
################################################################################
open_text() {
    local file=$1
    local line=$2
    log "Opening text file: $file at line $line at window:pane $KEY2PANE_WINDOW:$KEY2PANE_PANE" -v
    if running tmux; then
        key2pane -d /tmp/key2pane.log -l "$line" "$file"
    else
        nvim -c ":e $file | $line"
    fi
}
