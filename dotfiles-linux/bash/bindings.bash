source ~/dotfiles-linux/sh/fzf.sh
source ~/dotfiles-linux/scripts/fzf_help.bash

set -o vi

bind -r "\C-t"

bind '"\C-h":"\C-w"'
bind '"\C-t":vi-movement-mode'
bind -x '"\C-a": fzf_help'
bind -x '"\C-l": clear;'
bind -x '"\ed": fzf_home_cd' 
bind -x '"\eh": fzf_home'
bind -x '"\eo": fzf-file-widget'
bind -x '"\t": fzf_bash_completion'
