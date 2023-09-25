alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'

alias bat='bat --theme gruvbox-dark'
alias blueoff='bluetoothctl power off'
alias blueon='bluetoothctl power on; bluetoothctl discoverable on; bluetoothctl pairable on;'
alias dact='deactivate'
alias earbuds='bluetoothctl connect $EARBUDS'
alias headphones='bluetoothctl connect $HEADPHONES'
alias la='exa -hal --icons --git' 
alias ll='exa -hl --icons --git'
alias ls='exa -h --icons'
alias lsa='exa -ah --icons'
alias mutt='neomutt'
alias path='echo -e ${PATH//:/\\n}'
alias pdf="zathura $@"
alias py='python3'
alias reload='source ~/.zshrc'
alias ta='tmux attach'
alias tm='tmux-session ~'
alias ts="tmux-session $@"
alias vim='nvim $@'
alias wpip='wpy -m pip $@'
alias wpytest='wpy -m pytest $@'


alias graph="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

