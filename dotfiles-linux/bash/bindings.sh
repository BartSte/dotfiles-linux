source ~/dotfiles-linux/bash/fzf.sh
source ~/dotfiles-linux/scripts/fzf_help.bash

set -o vi

bind -r "\C-t"

bind '"\C-h":"\C-w"'
bind '"\C-t":vi-movement-mode'
bind -x '"\C-a": fzf_help'
bind -x '"\C-l": clear;'
bind -x '"\ed": fzf_home_dir' 
bind -x '"\eh": fzf_home_file'
bind -x '"\eo": fzf-file-widget'
bind -x '"\t": fzf_bash_completion'bind -r "\C-t"
