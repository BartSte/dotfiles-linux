source /usr/share/fzf/key-bindings.bash
source ~/dotfiles-linux/bash/fzf_bash_completion.bash

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

fzf_home_cd() {
    dir=$($FZF_ALT_D_COMMAND | eval "fzf $FZF_DEFAULT_OPTS $FZF_ALT_D_OPTS")
    cd $dir
}

