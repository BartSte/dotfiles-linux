bindkey -v

zle -N _fzf-dir-widget
zle -N _fzf-dir-widget-home
zle -N _fzf-file-widget-home
zle -N _fzf-file-widget-open
zle -N _fzf-file-widget-open-home
zle -N _fzf-help-widget
zle -N _fzf-rbw-widget

bindkey -M vicmd "\ef" fzf-file-widget
bindkey -M viins "\ef" fzf-file-widget
bindkey -M vicmd "\eF" _fzf-file-widget-home
bindkey -M viins "\eF" _fzf-file-widget-home

bindkey -M vicmd "\ed" _fzf-dir-widget
bindkey -M viins "\ed" _fzf-dir-widget
bindkey -M vicmd "\eD" _fzf-dir-widget-home
bindkey -M viins "\eD" _fzf-dir-widget-home

bindkey -M vicmd "\ec" fzf-cd-widget
bindkey -M viins "\ec" fzf-cd-widget
bindkey -M vicmd "\eC" _fzf-cd-widget-home
bindkey -M viins "\eC" _fzf-cd-widget-home

bindkey -M vicmd "\eo" _fzf-file-widget-open
bindkey -M viins "\eo" _fzf-file-widget-open
bindkey -M vicmd "\eO" _fzf-file-widget-open-home
bindkey -M viins "\eO" _fzf-file-widget-open-home

bindkey -M vicmd "^A" _fzf-help-widget
bindkey -M vicmd "^B" _fzf-rbw-widget
bindkey -M vicmd "^R" fzf-history-widget
bindkey -M viins "^A" _fzf-help-widget
bindkey -M viins "^B" _fzf-rbw-widget
bindkey -M viins "^R" fzf-history-widget
bindkey -M viins "^[[1;5C" forward-word
