set -o vi

bind '"\C-t":vi-movement-mode'
bind '"\C-h":"\C-w"'
bind -x '"\t": fzf_bash_completion'
bind -x '"\C-l": clear;'
bind -x '"\C-a": fzf_help;'
bind -x '"\eo": fzf-file-widget'
bind -x '"\eo": fzf-file-widget'

