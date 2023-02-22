set -o vi

bind -r "\C-t"

bind '"\C-t":vi-movement-mode'
bind '"\C-h":"\C-w"'

bind -x '"\C-a": fzf_help;'
bind -x '"\C-l": clear;'
bind -x '"\ed": fzf_home_dir' 
bind -x '"\eo": fzf-file-widget'
bind -x '"\eh": fzf_home_file'
bind -x '"\t": fzf_bash_completion'
