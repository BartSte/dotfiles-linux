source /usr/share/fzf/key-bindings.zsh

bindkey -v
bindkey -r "^T"
bindkey -r "^R"

bindkey -M vicmd "^R" fzf-history-widget
bindkey -M vicmd "\eo" fzf-file-widget

bindkey -M viins "^R" fzf-history-widget
bindkey -M viins "\eo" fzf-file-widget
bindkey -M viins -s '^H' '^W'

ZVM_VI_INSERT_ESCAPE_BINDKEY='^T'
