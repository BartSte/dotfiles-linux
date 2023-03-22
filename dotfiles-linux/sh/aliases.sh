alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'

alias path='echo -e ${PATH//:/\\n}'
alias vim='nvim'
alias mutt='neomutt'

alias py='python3'
alias tn='tmux new'
alias ta='tmux attach'
alias tm='sessionizer ~'
alias bat='bat --theme gruvbox-dark'
alias act='source .venv/bin/activate'
alias dact='deactivate'
alias blue='bluetoothctl connect $HEADPHONES'
alias blueon='bluetoothctl power on; bluetoothctl discoverable on; bluetoothctl pairable on;'
alias blueoff='bluetoothctl power off'

alias ls='exa -h --icons'
alias lsa='exa -ah --icons'
alias ll='exa -hl --icons'
alias la='exa -hal --icons' 

alias graph="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"