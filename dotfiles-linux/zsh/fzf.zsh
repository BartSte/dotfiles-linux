if [[ -f "$HOME/.fzf/shell/key-bindings.zsh" ]]; then
  source "$HOME/.fzf/shell/key-bindings.zsh"
else
  for p in \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/fzf/shell/key-bindings.zsh; do
    if [[ -f "$p" ]]; then
      source "$p"
      break
    fi
  done
fi

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

    export FZF_ALT_D_COMMAND="$FZF_ALT_C_COMMAND"
    export FZF_ALT_D_U_COMMAND="$FZF_ALT_C_U_COMMAND"
    export FZF_ALT_D_OPTS="$_FZF_BASE_OPTS \
	--bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_D_COMMAND\" \"$FZF_ALT_D_U_COMMAND\"))' \
	--preview '$_FZF_PREVIEW_OPTS_DIR'"
    export FZF_ALT_D_HOME_OPTS="$_FZF_BASE_OPTS \
            --bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_D_COMMAND . $HOME\" \"$FZF_ALT_D_U_COMMAND . $HOME\"))' \
            --preview '$_FZF_PREVIEW_OPTS_DIR'"

    export FZF_ALT_C_COMMAND="$_BASE_COMMAND --type d"
    export FZF_ALT_C_U_COMMAND="$_BASE_U_COMMAND --type d"
    export FZF_ALT_C_OPTS="$_FZF_BASE_OPTS \
	--bind 'ctrl-g:reload(eval \$(_toggle-unrestricted \"$FZF_ALT_C_COMMAND\" \"$FZF_ALT_C_U_COMMAND\"))' \
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

_fzf-file-widget-home() {
    _reset_unrestricted
    LBUFFER="${LBUFFER}$(eval "$FZF_CTRL_T_COMMAND . $HOME | fzf $FZF_CTRL_T_HOME_OPTS")"
    local ret=$?
    zle reset-prompt
    return $ret
}

_fzf-cd-widget-home() {
    _reset_unrestricted
    LBUFFER="${LBUFFER}$(eval "$FZF_ALT_C_COMMAND . $HOME | fzf $FZF_ALT_C_HOME_OPTS")"
    local ret=$?
    if [ $ret -eq 0 ]; then
        LBUFFER="builtin cd -- ${LBUFFER}"
        zle accept-line
    else
        zle reset-prompt
    fi
}

_fzf-dir-widget() {
    _reset_unrestricted
    LBUFFER="${LBUFFER}$(eval "$FZF_ALT_D_COMMAND | fzf $FZF_ALT_D_OPTS")"
    local ret=$?
    zle reset-prompt
    return $ret
}

_fzf-dir-widget-home() {
    _reset_unrestricted
    LBUFFER="${LBUFFER}$(eval "$FZF_ALT_D_COMMAND . $HOME | fzf $FZF_ALT_D_HOME_OPTS")"
    local ret=$?
    zle reset-prompt
    return $ret
}

_fzf-file-widget-open() {
    _reset_unrestricted
    LBUFFER="$(eval "$FZF_CTRL_T_COMMAND | fzf $FZF_CTRL_T_OPTS")"
    local ret=$?
    if [ $ret -eq 0 ]; then
        LBUFFER="open ${LBUFFER}"
        zle accept-line
    else
        zle reset-prompt
    fi
    return $ret
}

_fzf-file-widget-open-home() {
    _reset_unrestricted
    LBUFFER="$(eval "$FZF_CTRL_T_COMMAND . $HOME | fzf $FZF_CTRL_T_HOME_OPTS")"
    local ret=$?
    if [ $ret -eq 0 ]; then
        LBUFFER="open ${LBUFFER}"
        zle accept-line
    else
        zle reset-prompt
    fi
    return $ret
}

_fzf-rbw-widget() {
    $HOME/dotfiles-linux/scripts/fzfrbw
    local ret=$?
    zle reset-prompt
    return $ret
}

_fzf-prompts-widget() {
    filetype="${$(echo ${(z)BUFFER})%.[^.]*}"
    cmd="prompts {} -f $filetype 2>/dev/null || prompts {}"
    args="docstrings typehints refactor fix unittests"
    arg=$(echo $args | tr ' ' '\n' | fzf --preview $cmd)
    if [[ -n $arg ]]; then
        prompts $arg -f $filetype 2>/dev/null || prompts $arg
    fi
    zle reset-prompt
    return $ret
}
