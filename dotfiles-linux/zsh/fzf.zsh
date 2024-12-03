save-source /usr/share/fzf/key-bindings.zsh
save-source /usr/share/fzf-help/fzf-help.zsh

_load_fzf() {
    _BASE_COMMAND="fd --hidden --no-ignore-vcs --ignore-file $HOME/.ignore"
    _BASE_UNRESTRICTED_COMMAND="fd --unrestricted" 
    export FZF_ALT_C_COMMAND="$_BASE_COMMAND --type d"
    export FZF_ALT_C_UNRESTRICTED_COMMAND="$_BASE_UNRESTRICTED_COMMAND --type d"
    export FZF_ALT_D_COMMAND="$FZF_ALT_C_COMMAND"
    export FZF_ALT_D_UNRESTRICTED_COMMAND="$_BASE_UNRESTRICTED_COMMAND . $HOME"
    export FZF_ALT_H_COMMAND="$FZF_DEFAULT_COMMAND . $HOME"
    export FZF_ALT_H_UNRESTRICTED_COMMAND="$_BASE_COMMAND . $HOME"
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
    export FZF_CTRL_T_UNRESTRICED_COMMAND="$_BASE_UNRESTRICTED_COMMAND --type f"

    export FZF_DEFAULT_OPTS="--bind 'ctrl-p:toggle-preview'"

    _FZF_DEFAULT_OPTS="--header '<ctrl-p> toggle preview | <ctrl-g> toggle (un)restricted' \
        --height 49% \
        --layout=reverse \
        --preview-window=right,65% \
        --preview-window 'hidden'"

    _FZF_PREVIEW_OPTS_FILES='bat \
        --theme=gruvbox-dark \
        --style=numbers \
        --color=always \
        --line-range :500 {}'

    export FZF_CTRL_T_OPTS="$_FZF_DEFAULT_OPTS \
        --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_CTRL_T_COMMAND\" \"$FZF_CTRL_T_UNRESTRICED_COMMAND\"))' \
        --preview '$_FZF_PREVIEW_OPTS_FILES'"

    export FZF_ALT_H_OPTS="$_FZF_DEFAULT_OPTS \
        --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_H_COMMAND\" \"$FZF_ALT_H_UNRESTRICTED_COMMAND\"))' \
        --preview '$_FZF_PREVIEW_OPTS_FILES'"

    _FZF_PREVIEW_OPTS_DIR="exa \
        --color=always \
        --icons \
        -T -L 1 -a {} | head -200"

    export FZF_ALT_C_OPTS="$_FZF_DEFAULT_OPTS \
        --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_C_COMMAND\" \"$FZF_ALT_C_UNRESTRICTED_COMMAND\"))' \
        --preview '$_FZF_PREVIEW_OPTS_DIR'"

    export FZF_ALT_D_OPTS="$_FZF_DEFAULT_OPTS \
        --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_D_COMMAND\" \"$FZF_ALT_D_UNRESTRICTED_COMMAND\"))' \
        --preview '$_FZF_PREVIEW_OPTS_DIR'"

    export HELP_MESSAGE_RC="$HOME/dotfiles-linux/zsh/fzfhelprc.zsh"
    export FZF_HELP_SYNTAX='help'
    export CLI_OPTIONS_CMD="ag -o --numbers -- \$RE"

    export FZF_OPEN_OPTS="--preview 'bat --theme=gruvbox-dark --color=always --line-range :500 {}' --preview-window 'hidden'"

    export FZF_OPEN_REGEX_EXTRA=$(~/dotfiles-linux/tmux/tmux-fzf-open/regex-extra)
}

_toggle-unrestricted() {
    if [ -f /tmp/fzf-unrestricted ]; then
        rm /tmp/fzf-unrestricted
        echo $1
    else
        touch /tmp/fzf-unrestricted
        echo $2
    fi
}


fzf-dir-widget() {
    _OLD_COMMAND=$FZF_CTRL_T_COMMAND
    _OLD_OPTS=$FZF_CTRL_T_OPTS

    FZF_CTRL_T_COMMAND=$FZF_ALT_D_COMMAND
    FZF_CTRL_T_OPTS=$FZF_ALT_D_OPTS

    fzf-file-widget

    FZF_CTRL_T_COMMAND=$_OLD_COMMAND
    FZF_CTRL_T_OPTS=$_OLD_OPTS
}

fzf-file-widget-home() {
    _OLD_COMMAND=$FZF_CTRL_T_COMMAND
    _OLD_OPTS=$FZF_CTRL_T_OPTS

    FZF_CTRL_T_COMMAND=$FZF_ALT_H_COMMAND
    FZF_CTRL_T_OPTS=$FZF_ALT_H_OPTS

    fzf-file-widget

    FZF_CTRL_T_COMMAND=$_OLD_COMMAND
    FZF_CTRL_T_OPTS=$_OLD_OPTS
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
    BUFFER='file=$(eval "$FZF_CTRL_T_COMMAND | fzf $FZF_CTRL_T_OPTS") && $EDITOR $file' || return
    zle accept-line
}

fzfrbw-widget() {
    $HOME/dotfiles-linux/scripts/fzfrbw
    zle reset-prompt
}

