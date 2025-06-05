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

################################################################################
# Runs `aider` if no arguments are provided, or `prompts-aider` with arguments
# otherwise.
#
# Aider environment variables are set based on the `PROJECTRC` variable and the
# hostname.
# ###############################################################################
ai() {
    local dir
    dir=$HOME/dotfiles-linux/aider
    save-source $dir/host_settings.zsh
    save-source $dir/$PROJECTRC.zsh

    if [[ $# -eq 0 ]]; then
        aider
    else
        prompts $@ --action aider
    fi
}

aibase() {
  GIT_DIR=$HOME/dotfiles.git \
  GIT_WORK_TREE=$HOME \
  ai "$@"
}

ailin() {
  GIT_DIR=$HOME/.dotfiles-linux.git \
  GIT_WORK_TREE=$HOME \
  ai "$@"
}
