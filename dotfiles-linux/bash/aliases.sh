alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'
alias path='echo -e ${PATH//:/\\n}'

alias base='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias lin='/usr/bin/git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME'
alias sec='/usr/bin/git --git-dir=$HOME/dotfiles-secret.git/ --work-tree=$HOME'
alias bases='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME status --untracked-files=no'
alias lins='/usr/bin/git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME status --untracked-files=no'
alias secs='/usr/bin/git --git-dir=$HOME/dotfiles-secret.git/ --work-tree=$HOME status --untracked-files=no'
alias dots='bases && lins && secs'

alias bat='bat --theme gruvbox-dark'
alias ta='tmux attach'
alias tn='tmux new'
alias rm='trash-put'
alias remove='/usr/bin/rm'
alias blue='bluetoothctl'
alias blueon='~/dotfiles-linux/scripts/enable_bluetooth.bash'
alias blueoff='bluetoothctl power off'

alias ls='exa -h --icons'
alias lsa='exa -ah --icons'
alias ll='exa -hl --icons'
alias la='exa -hal --icons' 

