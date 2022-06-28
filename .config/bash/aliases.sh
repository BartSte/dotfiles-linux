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
alias rm='trash-put'
alias remove='/usr/bin/rm'

alias ls='exa -h --icons'
alias lsa='exa -ah --icons'
alias ll='exa -hal --no-permissions --no-user --icons'
alias la='exa -hal --no-permissions --no-user --icons' 

