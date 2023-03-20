source /usr/share/fzf/key-bindings.zsh

_fzf_compgen_path() {
  fd --hidden --follow --ignore-file $HOME/.ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --ignore-file $HOME/.ignore . "$1"
}

__select() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local item
  eval $1 | eval "fzf $FZF_DEFAULT_OPTS $2" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

fzf_home() {
    LBUFFER="${LBUFFER}$(__select $FZF_ALT_H_COMMAND $FZF_ALT_H_OPTS)"
    local ret=$?
    zle reset-prompt
    return $ret
}

zle -N fzf_home_dir
zle -N fzf_home_file
bindkey -M vicmd "\eh" fzf_home
bindkey -M vicmd "\eo" fzf-file-widget

bindkey -M viins "^A" fzf_help;
bindkey -M viins "\eh" fzf_home
bindkey -M viins "\eo" fzf-file-widget

