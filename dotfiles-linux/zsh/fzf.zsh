if [[ -z ${__DOTFILES_FZF_ENV_LOADED:-} ]]; then
  source "$HOME/dotfiles-linux/zsh/fzf-env.zsh"
fi

if [[ -n "$ZSH_VERSION" && -z ${__DOTFILES_FZF_BINDINGS_LOADED:-} ]]; then
  typeset -g __DOTFILES_FZF_BINDINGS_LOADED=1
  if [[ -f /usr/share/fzf-help/fzf-help.zsh ]]; then
    save-source /usr/share/fzf-help/fzf-help.zsh
  fi
  for p in \
    "$HOME/.fzf/shell/key-bindings.zsh" \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/fzf/shell/key-bindings.zsh; do
    if [[ -f "$p" ]]; then
      source "$p"
      break
    fi
  done
fi

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
