bindkey -v

zle -N fzf-cd-widget-home
zle -N fzf-cd-widget-no-ignore
zle -N fzf-file-widget-home
zle -N fzf-file-widget-no-ignore
zle -N fzf-help-widget
zle -N fzfrbw-widget
zle -N man-widget

bindkey -M vicmd "\eC" fzf-cd-widget-no-ignore
bindkey -M vicmd "\eH" man-widget
bindkey -M vicmd "\eO" fzf-file-widget-no-ignore
bindkey -M vicmd "\ed" fzf-cd-widget-home
bindkey -M vicmd "\eh" fzf-file-widget-home
bindkey -M vicmd "\eo" fzf-file-widget
bindkey -M vicmd "^A" fzf-help-widget
bindkey -M vicmd "^B" fzfrbw-widget
bindkey -M vicmd "^R" fzf-history-widget
bindkey -M vicmd "^T" vi-cmd-mode
bindkey -M vicmd "^[[1;5C" forward-word

bindkey -M vicmd -s "^[[1;5D" "^W"

bindkey -M viins "\eC" fzf-cd-widget-no-ignore
bindkey -M viins "\eH" man-widget
bindkey -M viins "\eO" fzf-file-widget-no-ignore
bindkey -M viins "\ed" fzf-cd-widget-home
bindkey -M viins "\eh" fzf-file-widget-home
bindkey -M viins "\eo" fzf-file-widget
bindkey -M viins "^A" fzf-help-widget
bindkey -M viins "^B" fzfrbw-widget
bindkey -M viins "^R" fzf-history-widget
bindkey -M viins "^T" vi-cmd-mode
bindkey -M viins "^[[1;5C" forward-word

bindkey -M viins -s "^[[1;5D" "^W"
bindkey -M viins -s '^H' '^W'
