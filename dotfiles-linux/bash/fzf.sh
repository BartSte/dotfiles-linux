source ~/dotfiles-linux/bash/functions.sh
save_source /usr/share/fzf/key-bindings.bash
save_source ~/dotfiles-linux/scripts/fzf_help.bash
save_source ~/clones/fzf-tab-completion/bash/fzf-bash-completion.sh

_fzf_compgen_path() {
  fd --hidden --follow --ignore-file $HOME/.ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --ignore-file $HOME/.ignore . "$1"
}

fzf_home() {
    value=$($FZF_ALT_H_COMMAND | eval "fzf $FZF_DEFAULT_OPTS $FZF_ALT_H_OPTS")
    append_line $value
}

fkill() {
  local pid

  pid="$(
    ps -ef \
      | sed 1d \
      | fzf -m \
      | awk '{print $2}'
  )" || return

  kill -"${1:-9}" "$pid"
}
set -o vi

bind -m vi-command -x '"\eh": fzf_home'
bind -m vi-command -x '"\eo": fzf-file-widget'

bind -m vi-insert -x '"\em": fzf_help'
bind -m vi-insert -x '"\eh": fzf_home'
bind -m vi-insert -x '"\eo": fzf-file-widget'
bind -m vi-insert -x '"\t": fzf_bash_completion'
