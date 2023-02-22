set -o vi

bind -r "\C-t"

bind '"\C-t":vi-movement-mode'
bind '"\C-h":"\C-w"'

bind -x '"\C-a": fzf_help;'
bind -x '"\C-l": clear;'
bind -x '"\eC": fzf_cd_home' 
bind -x '"\ep": zdr' 
bind -x '"\eo": fzf-file-widget'
bind -x '"\eO": fzf_file_home'
bind -x '"\t": fzf_bash_completion'
