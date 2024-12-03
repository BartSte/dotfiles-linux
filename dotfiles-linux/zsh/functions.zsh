fkill() {
    local pid

    pid="$(
        ps -ef |
            sed 1d |
            fzf -m |
            awk '{print $2}'
    )" || return

    kill -"${1:-9}" "$pid"
}

fullsync() {
    echo "### Syncing rbw"
    rbw unlock && rbw sync

    echo "\n### Syncing dotfiles"
    dotu

    echo "\n### Syncing dropbox"
    rclone bisync dropbox: ~/dropbox

    echo "\n### Syncing calendar"
    mycalsync

    echo "\n### Syncing mail"
    mailsync
}
