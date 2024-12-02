save-source /usr/share/fzf/key-bindings.zsh
save-source /usr/share/fzf-help/fzf-help.zsh

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

fzf-dir-widget() {
    _OLD_FZF_CTRL_T_COMMAND=$FZF_CTRL_T_COMMAND
    _OLD_FZF_CTRL_T_OPTS=$FZF_CTRL_T_OPTS

    FZF_CTRL_T_COMMAND=$FZF_ALT_D_COMMAND
    FZF_CTRL_T_OPTS=$FZF_ALT_D_OPTS

    fzf-file-widget

    FZF_CTRL_T_COMMAND=$_OLD_FZF_CTRL_T_COMMAND
    FZF_CTRL_T_OPTS=$_OLD_FZF_CTRL_T_OPTS
}

fzf-file-widget-home() {
    _OLD_FZF_CTRL_T_COMMAND=$FZF_CTRL_T_COMMAND
    _OLD_FZF_CTRL_T_OPTS=$FZF_CTRL_T_OPTS

    FZF_CTRL_T_COMMAND=$FZF_ALT_H_COMMAND
    FZF_CTRL_T_OPTS=$FZF_ALT_H_OPTS

    fzf-file-widget

    FZF_CTRL_T_COMMAND=$_OLD_FZF_CTRL_T_COMMAND
    FZF_CTRL_T_OPTS=$_OLD_FZF_CTRL_T_OPTS
}

fzf-cd-widget-home() {
    _OLD_FZF_ALT_C_COMMAND=$FZF_ALT_C_COMMAND
    _OLD_FZF_ALT_C_OPTS=$FZF_ALT_C_OPTS

    FZF_ALT_C_COMMAND=$FZF_ALT_D_COMMAND
    FZF_ALT_C_OPTS=$FZF_ALT_D_OPTS

    fzf-cd-widget

    FZF_ALT_C_COMMAND=$_OLD_FZF_ALT_C_COMMAND
    FZF_ALT_C_OPTS=$_OLD_FZF_ALT_C_OPTS
}

fzf-file-widget-open() {
    BUFFER="$EDITOR \$(fzf)"
    zle accept-line
}

fzfrbw-widget() {
    $HOME/dotfiles-linux/scripts/fzfrbw
    zle reset-prompt
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
