################################################################################
# Use fzf to select multiple processes to kill
################################################################################
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}') || return
    xargs kill -"${1:-9}" <<<"$pid"
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

###############################################################################
# Run aider
# Before, specify host and project settings are loaded.
###############################################################################
ai() {
    local dir
    dir=$HOME/dotfiles-linux/aider
    if [[ -f $dir/host_settings.zsh ]]; then
        source $dir/host_settings.zsh
    fi
    if [[ -f $dir/$PROJECTRC.zsh ]]; then
        source $dir/$PROJECTRC.zsh
    fi

    # If no args, run aider solo
    if [[ $# -eq 0 ]]; then
        aider
    else # Otherwise, run aider --message $(prompts <options> <command>) [files]
        # TODO
    fi
}
