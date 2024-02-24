alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'
alias .....='cd ./../../../../'
alias ......='cd ./../../../../../'

alias bat='bat --theme gruvbox-dark'
alias blueoff='bluetoothctl power off'
alias blueon='bluetoothctl power on; bluetoothctl discoverable on; bluetoothctl pairable on;'
alias dact='deactivate'
alias dsize='du -h -d1' # use the du command for further inspection
alias earbuds='bluetoothctl connect $EARBUDS'
alias headphones='bluetoothctl connect $SONY'
alias htop='btop'
alias la='exa -hal --icons --git'
alias ll='exa -hl --icons --git'
alias ls='exa -h --icons'
alias lsa='exa -ah --icons'
alias mutt='neomutt'
alias oldheadphones='bluetoothctl connect $HEADPHONES'
alias path='echo -e ${PATH//:/\\n}'
alias py='python3'
alias reload='source ~/.zshrc && source ~/.zshenv'
alias rm='rm -i'
alias ta='tmux attach'
alias tm='tmux-session ~'
alias ts='tmux-session $@'
alias unlock='rbw unlock'
alias v='nvim $@'
alias wipdb='wpy -m ipdb $@'
alias wpip='wpy -m pip $@'
alias wpytest='wpy -m pytest $@'
alias yay='export MAKEFLAGS="-j$(nproc)" && yay $@'

alias sudo='sudo '
