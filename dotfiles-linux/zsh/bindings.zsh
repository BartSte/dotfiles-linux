source $dir_zsh/fzf.zsh

bindkey -v

zle -N fzf_home
zle -N fzf_help

bindkey -M vicmd "\eh" fzf_home
bindkey -M vicmd "\eo" fzf-file-widget

bindkey -M viins "\eh" fzf_home
bindkey -M viins "\eo" fzf-file-widget
bindkey -M viins "^A" fzf_help
bindkey -M viins '^T' vi-cmd-mode
bindkey -M viins -s '^H' '^W'
