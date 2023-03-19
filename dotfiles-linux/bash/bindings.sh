set -o vi

bind -m vi-command -r "\C-t"
bind -m vi-insert '"\C-h":"\C-w"'
bind -m vi-insert '"\C-t":vi-movement-mode'
bind -m vi-insert -x '"\C-l": clear;'
