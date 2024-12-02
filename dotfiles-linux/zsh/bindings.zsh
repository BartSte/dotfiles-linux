bindkey -v

zle -N fzf-cd-widget
zle -N fzf-cd-widget-no-ignore
zle -N fzf-file-widget-home
zle -N fzf-file-widget-no-ignore
zle -N fzf-help-widget
zle -N fzfrbw-widget

bindkey -M vicmd "\ec" fzf-cd-widget
bindkey -M viins "\ec" fzf-cd-widget

bindkey -M vicmd "\ef" fzf-file-widget
bindkey -M viins "\ef" fzf-file-widget

bindkey -M vicmd "\eh" fzf-file-widget-home
bindkey -M viins "\eh" fzf-file-widget-home

bindkey -M vicmd "^A" fzf-help-widget
bindkey -M viins "^A" fzf-help-widget
bindkey -M vicmd "^B" fzfrbw-widget
bindkey -M viins "^B" fzfrbw-widget
bindkey -M vicmd "^R" fzf-history-widget
bindkey -M viins "^R" fzf-history-widget
bindkey -M viins "^[[1;5C" forward-word
