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
# Run aider --yes-always --message <message> <file1> <file2> ... where the
# <message> is retrieved from bartste-prompts.
#
# The command line interface is the same as `prompts --help`. If no arguments
# are applied, aider is executed without arguments (entering chat mode).
###############################################################################
ai() {
    if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
        prompts --help
        return
    fi

    local dir
    dir=$HOME/dotfiles-linux/aider
    save-source $dir/host_settings.zsh
    save-source $dir/$PROJECTRC.zsh

    if [[ $# -gt 0 ]]; then
        local args message files
        args=$(prompts $@ --json)
        message=$(jq -r '.prompt' <<<$args)
        # TODO multiple files are not yet supported ....
        # files=$(jq -r '.files[]' <<<$args | tr '\n' ' ')
        aider --yes-always --message "$message"

    else
        aider
    fi
}
