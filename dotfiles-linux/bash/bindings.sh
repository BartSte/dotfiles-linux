set -o vi
bind '"\C-f":vi-movement-mode'
bind '"\C-h":"\C-w"'
bind -x '"\t": fzf_bash_completion'
bind -x '"\el": clear;'
bind -x '"\C-a": _fzf_help;'

