bindkey -v
zle -N _fzf_git_branches
zle -N fzf_home
zle -N fzf-help-widget

bindkey -M vicmd "^A" fzf-help-widget
bindkey -M viins "^A" fzf-help-widget

bindkey -M viins "\eh" fzf_home
bindkey -M vicmd "\eh" fzf_home
bindkey -M vicmd "^T" vi-cmd-mode
bindkey -M vicmd "\eo" fzf-file-widget
bindkey -M vicmd "\eB" _fzf_git_branches

bindkey -M viins "^T" vi-cmd-mode
bindkey -M viins "\eo" fzf-file-widget
bindkey -M viins -s '^H' '^W'
bindkey -M viins "\eB" _fzf_git_branches
