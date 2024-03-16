#!/usr/bin/env bash
set -euo pipefail
this_dir=$(dirname "$(readlink -f "$0")")

. "$this_dir"/wsl.bash
. "$this_dir"/logger.bash

open_url() {
    log "Url detected, opening in browser." -v
    if running_wsl; then
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
    local path win file line
    path=""
    win=false
    while [[ $# -gt 0 ]]; do
        case $1 in
        -w | --win)
            win=true
            ;;
        *)
            if [[ -z $path ]]; then
                path=$1
            else
                echo "Unknown option: $1" >&2
                exit 1
            fi
            ;;
        esac
        shift
    done

    file=$(echo "$path" | cut -d ':' -f 1 | convert_win_path)
    line=$(echo "$path" | cut -d ':' -f 2 -s) # -s ensures nothing is returned if ':' is not found
    line=${line:-1}
    log "Opening text file: $file at line $line at window:pane $TVIM_WINDOW:$TVIM_PANE" -v
    if running_tmux; then
        tvim -d /tmp/tvim.log -l $line $file
    else
        nvim -c ":e $file|$line"
    fi
}
