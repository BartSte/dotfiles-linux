alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ./../../'
alias ....='cd ./../../../'
alias .....='cd ./../../../../'
alias ......='cd ./../../../../../'

alias act='source .venv/bin/activate'
alias bat='bat --theme gruvbox-dark'
alias blueoff='bluetoothctl power off'
alias blueon='bluetoothctl power on; bluetoothctl discoverable on; bluetoothctl pairable on;'
alias chrome='google-chrome-stable --ozone-platform=wayland'
alias dact='deactivate'
alias dropsync='rclone bisync dropbox: ~/dropbox --conflict-resolve path1 --conflict-loser num --remove-empty-dirs --progress'
alias dsize='du -h -d1' # use the du command for further inspection
alias earbuds='bluetoothctl connect $EARBUDS'
alias fps="ps aux | fzf"
alias headphones='bluetoothctl connect $SONY'
alias ipython='if [ $VIRTUAL_ENV ]; then python -m IPython; else ipython; fi'
alias mutt='neomutt'
alias o='open'
alias oldheadphones='bluetoothctl connect $HEADPHONES'
alias path='echo -e ${PATH//:/\\n}'
alias py='python3'
alias sc-im='TERM=xterm-256color sc-im'
alias sudo='sudo '
alias suspend="systemctl suspend"
alias ta='tmux -u attach'
alias tm='tmux-session ~ --hook "tmux neww $EDITOR; tmux swap-window -t 0"'
alias tmka='tmux kill-server'
alias tmks='tmux kill-session'
alias ts='tmux-session'
alias unl='rbw unlock'
alias v='nvim'
alias yay='export MAKEFLAGS="-j$(nproc)" && yay'

qhash() {
    hash $1 2>/dev/null
}

qhash exa && alias la='exa -hal --icons --git'
qhash exa && alias ll='exa -hl --icons --git'
qhash exa && alias ls='exa -h --icons'
qhash exa && alias lsa='exa -ah --icons'
qhash exa && alias tree='exa -T --icons'
qhash safe-rm && alias rm='/usr/lib/safe-rm/rm'
qhash trash-put && alias dl='trash-put'
