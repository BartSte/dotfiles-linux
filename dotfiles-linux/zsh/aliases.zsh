alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'

alias py='python3'
alias ta='tmux attach'
alias tm='tmux-session ~'
alias ls='exa -h --icons'
alias ts="tmux-session $@"
alias ll='exa -hl --icons --git'
alias la='exa -hal --icons --git' 
alias vim='nvim $@'
alias pdf="zathura $@"
alias lsa='exa -ah --icons'
alias bat='bat --theme gruvbox-dark'
alias mutt='neomutt'
alias dact='deactivate'
alias path='echo -e ${PATH//:/\\n}'
alias reload='source ~/.zshrc'
alias summary='gtm report -all=true -full-message=false -this-week=true -format=summary'
alias timeline='gtm report -all=true -full-message=false -this-week=true -format=timeline-hours'
alias blueon='bluetoothctl power on; bluetoothctl discoverable on; bluetoothctl pairable on;'
alias blueoff='bluetoothctl power off'
alias earbuds='bluetoothctl connect $EARBUDS'
alias headphones='bluetoothctl connect $HEADPHONES'

alias graph="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

