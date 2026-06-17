if [[ -n ${__DOTFILES_FZF_ENV_LOADED:-} ]]; then
    return
fi
typeset -g __DOTFILES_FZF_ENV_LOADED=1

_fzfenv() {
    _BASE_COMMAND="fd --hidden --no-ignore-vcs --ignore-file $HOME/.ignore"

    _BASE_U_COMMAND="fd --unrestricted"

    _FZF_BASE_OPTS="\
        --header '<ctrl-p> toggle preview | <ctrl-g> toggle (un)restricted' \
        --height 49% \
        --preview-window=right,65% \
        --preview-window 'hidden'"

    _FZF_PREVIEW_OPTS_FILES='\
        bat \
        --theme=gruvbox-dark \
        --style=numbers \
        --color=always \
        --line-range :500 {}'

    _FZF_PREVIEW_OPTS_DIR="\
        exa --color=always --icons -T -L 1 -a {} | head -200"

    export FZF_DEFAULT_OPTS="--bind 'ctrl-p:toggle-preview' --layout=reverse"

    export FZF_CTRL_T_COMMAND="$_BASE_COMMAND --type f"
    export FZF_CTRL_T_U_COMMAND="$_BASE_U_COMMAND --type f"
    export FZF_CTRL_T_OPTS="$_FZF_BASE_OPTS \
	--bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_CTRL_T_COMMAND\" \"$FZF_CTRL_T_U_COMMAND\"))' \
	--preview '$_FZF_PREVIEW_OPTS_FILES'"
    export FZF_CTRL_T_HOME_OPTS="$_FZF_BASE_OPTS \
            --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_CTRL_T_COMMAND . $HOME\" \"$FZF_CTRL_T_U_COMMAND . $HOME\"))' \
            --preview '$_FZF_PREVIEW_OPTS_FILES'"

    export FZF_ALT_C_COMMAND="$_BASE_COMMAND --type d"
    export FZF_ALT_C_U_COMMAND="$_BASE_U_COMMAND --type d"
    export FZF_ALT_C_OPTS="$_FZF_BASE_OPTS \
	--bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_C_COMMAND\" \"$FZF_ALT_C_U_COMMAND\"))' \
	--preview '$_FZF_PREVIEW_OPTS_DIR'"
    export FZF_ALT_C_HOME_OPTS="$_FZF_BASE_OPTS \
            --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_C_COMMAND . $HOME\" \"$FZF_ALT_C_U_COMMAND . $HOME\"))' \
            --preview '$_FZF_PREVIEW_OPTS_DIR'"

    export FZF_ALT_D_COMMAND="$FZF_ALT_C_COMMAND"
    export FZF_ALT_D_U_COMMAND="$FZF_ALT_C_U_COMMAND"
    export FZF_ALT_D_OPTS="$_FZF_BASE_OPTS \
	--bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_D_COMMAND\" \"$FZF_ALT_D_U_COMMAND\"))' \
	--preview '$_FZF_PREVIEW_OPTS_DIR'"
    export FZF_ALT_D_HOME_OPTS="$_FZF_BASE_OPTS \
            --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_D_COMMAND . $HOME\" \"$FZF_ALT_D_U_COMMAND . $HOME\"))' \
            --preview '$_FZF_PREVIEW_OPTS_DIR'"
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

_reset_unrestricted() {
    if [ -f /tmp/fzf-unrestricted ]; then
        rm /tmp/fzf-unrestricted
    fi
}
