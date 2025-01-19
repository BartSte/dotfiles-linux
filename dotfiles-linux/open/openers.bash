#!/usr/bin/env bash
set -euo pipefail
this_dir=$(dirname "$(readlink -f "$0")")

. "$this_dir"/logger.bash
. "$this_dir"/helpers.bash

open_url() {
    log "Url detected, opening in browser." -v
    if is_running wsl; then
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
# The window 0 and pane 0 are used to open the file in tmux. If tmux is running
# and we are opening the file in another pane, the key2pane command is used.
#
# If the -w or --win option is used, the path is converted to a wsl path if wsl
# is running.
################################################################################
open_text() {
    local file line
    file=$1
    line=$2
    log "Opening text file: $file at line $line" -v

    if is_running tmux && [[ $(tmux display-message -p '#I:#P') != "0:0" ]]; then
        log "Opening text file via key2pane" -v
        key2pane --loglevel INFO -w 0 -i 0 "$file" "$line"
    else
        log "Opening text file in nvim" -v
        nvim -c ":e $file | $line"
    fi
}
