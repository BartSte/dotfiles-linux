################################################################################
# Use fzf to select multiple processes to kill
################################################################################
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}') || return
    xargs kill -"${1:-9}" <<<"$pid"
}

################################################################################
# Evaluate math expressions with bc -l
################################################################################
calc() {
    bc -l <<<"scale=10; $*"
}

################################################################################
# Sync all programs
################################################################################
fullsync() {
    echo "### Syncing rbw"
    rbw unlock && rbw sync

    echo "\n### Syncing dotfiles"
    dotu

    echo "\n### Syncing calendar"
    mycalsync

    echo "\n### Syncing mail"
    mailsync

    echo "\n### Syncing dropbox"
    rclone bisync dropbox: ~/dropbox
}

################################################################################
# Sync all programs
################################################################################
urlencode() {
    printf '%s' "$1" | jq -sRr @uri
}

################################################################################
# Print the contents of multiple files with headers
################################################################################
ctx() {
    for file in "$@"; do
        echo
        echo "===== $file ====="
        cat "$file"
    done
}

################################################################################
# Delete empty directories recursively
################################################################################
rmemptydirs() {
    find "${@:-.}" -depth -type d -empty -delete
}
