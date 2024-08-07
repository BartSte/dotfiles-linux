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

fzfrbw-widget() {
    $HOME/dotfiles-linux/scripts/fzfrbw
    zle reset-prompt
}

man-widget() {
    [[ -z $BUFFER ]] || eval "man $BUFFER"
    zle reset-prompt
}

fzf-file-widget-no-ignore() {
    _OLD_FZF_CTRL_T_COMMAND=$FZF_CTRL_T_COMMAND
    FZF_CTRL_T_COMMAND="fd --hidden --no-ignore --type f"

    fzf-file-widget

    FZF_CTRL_T_COMMAND=$_OLD_FZF_CTRL_T_COMMAND
}

fzf-cd-widget-no-ignore() {
    _OLD_FZF_ALT_C_COMMAND=$FZF_ALT_C_COMMAND
    FZF_ALT_C_COMMAND="fd --hidden --no-ignore --type d"

    fzf-cd-widget

    FZF_ALT_C_COMMAND=$_OLD_FZF_ALT_C_COMMAND
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
