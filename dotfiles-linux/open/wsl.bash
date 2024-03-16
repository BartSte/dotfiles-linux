#!/usr/bin/env bash
set -euo pipefail
this_dir=$(dirname "$(readlink -f "$0")")

. "$this_dir"/logger.bash
. "$this_dir"/conditions.bash

################################################################################
# Tried to convert a windows path to a wsl path, if wsl is running. If wsl is
# not running, the path is returned as is.
################################################################################
convert_win_path() {
    local path=${1:-$(cat)}
    if running_wsl; then
        wslpath -u "$path" || {
            log "Failed to convert windows path to wsl path: $path"
            exit 1
        }
    else
        echo "$path"
    fi
}
