# To set the cursor block to inverse (such it shows the underlying character)
# right click on the title bar and go to Properties>Terminal>Cursor Colors>Inverse
# colors.

function get_ignored_directories() {
    readarray directories < ~/.ignore
    surround_by_quotes "${directories[@]}"
}

function surround_by_quotes() {
    ignored_directories=()
    for directory_trailing_space in "$@"; do
        directory=${directory_trailing_space::-1}
        ignored_directories+=("-not -path \"${directory}\"")
    done
}

get_ignored_directories
PROMPT_COMMAND='echo -en "\033]0;$(hostname) @ $(pwd)\a"'
export PS0="\e[2 q"
export PS1="\[\033[38;5;201m\]\\$\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;51m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;172m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"
export GPG_TTY=$(tty)
export EDITOR='vim'
export FZF_DEFAULT_COMMAND="ag --hidden --skip-vcs-ignores --path-to-ignore $HOME/.ignore -g '' ." 
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_COMPLETION_TRIGGER=''
export FZF_ALT_C_COMMAND="find -type d ${ignored_directories[@]}"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ...'
alias ....='cd ....'
alias path='echo -e ${PATH//:/\\n}'
alias base='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias lin='/usr/bin/git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME'
alias bat=batcat
alias ps=powershell.exe
alias ta='tmux attach'
alias tn='tmux new'

alias ls='ls -h --color'
alias la='ls -A' 
alias ll='ls -l'
alias lal='ls -Al'

set -o vi
bind '"kj":vi-movement-mode'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
