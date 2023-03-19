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

fzf_home_file() {
    $FZF_CTRL_T_COMMAND . ~ | fzf-file-widget
}

fzf_home_dir() {
    $FZF_ALT_C_COMMAND . ~ | fzf-file-widget
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

bind -m vi-command -x '"\ed": fzf_home_dir' 
bind -m vi-command -x '"\eh": fzf_home_file'
bind -m vi-command -x '"\eo": fzf-file-widget'

bind -m vi-insert -x '"\C-a": fzf_help;'
bind -m vi-insert -x '"\ed": fzf_home_dir' 
bind -m vi-insert -x '"\eh": fzf_home_file'
bind -m vi-insert -x '"\eo": fzf-file-widget'
bind -m vi-insert -x '"\t": fzf_bash_completion'
