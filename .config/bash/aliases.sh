alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'
alias path='echo -e ${PATH//:/\\n}'

alias base='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias lin='/usr/bin/git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME'

alias bat='batcat'
alias ta='tmux attach'
alias tn='tmux new'
alias cc='clear'
alias fd='fdfind'
alias tp='trash-put'

alias ls='ls -h --color'
alias la='ls -A' 
alias ll='ls -l'
alias lal='ls -Al'

