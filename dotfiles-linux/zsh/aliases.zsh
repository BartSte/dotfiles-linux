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
alias mutt='neomutt'
alias oldheadphones='bluetoothctl connect $HEADPHONES'
alias path='echo -e ${PATH//:/\\n}'
alias py='python3'
alias sudo='sudo '
alias ta='tmux -u attach'
alias tm='tmux-session ~'
alias ts='tmux-session'
alias unl='rbw unlock'
alias v='nvim'
alias wipdb='wpy -m ipdb'
alias wpip='wpy -m pip'
alias wpytest='wpy -m pytest'
alias yay='export MAKEFLAGS="-j$(nproc)" && yay'
alias dropsync='rclone bisync dropbox: ~/dropbox'
alias o='open'
alias suspend="systemctl suspend"

qhash() {
    hash $1 2>/dev/null
}

qhash exa && alias la='exa -hal --icons --git'
qhash exa && alias ll='exa -hl --icons --git'
qhash exa && alias ls='exa -h --icons'
qhash exa && alias lsa='exa -ah --icons'
qhash safe-rm && alias rm='echo "Tip: use dl to delete to trash" > /dev/stderr; /usr/lib/safe-rm/rm -i'
qhash trash-put && alias dl='trash-put'
