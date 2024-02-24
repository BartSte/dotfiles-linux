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
alias ta='tmux attach'
alias tm='tmux-session ~'
alias ts='tmux-session $@'
alias unlock='rbw unlock'
alias v='nvim $@'
alias wipdb='wpy -m ipdb $@'
alias wpip='wpy -m pip $@'
alias wpytest='wpy -m pytest $@'
alias yay='export MAKEFLAGS="-j$(nproc)" && yay $@'

# Safety aliases. dl is used instead of rm. This avoids getting careless when
# using rm on other system, as a habit of using dl is formed. When rm is
# needed, /bin/rm or /usr/bin/rm should be with the -I flag. 
# TODO: If the -f or --force flag is detected, raise a warning that the user
# must reply with yes or no.
alias dl='trash-put $@' alias rm='echo "Use dl instead of rm. If you need rm,
use /bin/rm" > /dev/stderr && echo $@ > /dev/null' alias /bin/rm='/bin/rm -I
$@' alias /usr/bin/rm='/usr/bin/rm -I $@'

# Ensure sudo is used with aliases
alias sudo='sudo '
