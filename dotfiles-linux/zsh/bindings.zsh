bindkey -v

zle -N _fzf_git_branches
zle -N fzf-cd-widget-home
zle -N fzf-file-widget-home
zle -N fzf-help-widget
zle -N fzfrbw-widget
zle -N man-widget

bindkey -M vicmd "\eB" _fzf_git_branches
bindkey -M vicmd "\eH" man-widget
bindkey -M vicmd "\ed" fzf-cd-widget-home
bindkey -M vicmd "\eh" fzf-file-widget-home
bindkey -M vicmd "\eo" fzf-file-widget
bindkey -M vicmd "^A" fzf-help-widget
bindkey -M vicmd "^B" fzfrbw-widget
bindkey -M vicmd "^R" fzf-history-widget
bindkey -M vicmd "^T" vi-cmd-mode

bindkey -M viins "\eB" _fzf_git_branches
bindkey -M viins "\eH" man-widget
bindkey -M viins "\ed" fzf-cd-widget-home
bindkey -M viins "\eh" fzf-file-widget-home
bindkey -M viins "\eo" fzf-file-widget
bindkey -M viins "^A" fzf-help-widget
bindkey -M viins "^B" fzfrbw-widget
bindkey -M viins "^R" fzf-history-widget
bindkey -M viins "^T" vi-cmd-mode
bindkey -M viins -s '^H' '^W'
