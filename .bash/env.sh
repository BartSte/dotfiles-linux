. ~/.bash/helpers.sh

get_ignored_directories

export PROMPT_COMMAND='echo -en "\033]0;$(hostname) @ $(pwd)\a"'
export PS0="\e[2 q"
export PS1="\[\033[38;5;201m\]\\$\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;51m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;172m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"
export GPG_TTY=$(tty)
export EDITOR='vim'
export FZF_DEFAULT_COMMAND="ag --hidden --skip-vcs-ignores --path-to-ignore $HOME/.ignore -g '' ." 
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_COMPLETION_TRIGGER=''
export FZF_ALT_C_COMMAND="find -type d ${ignored_directories[@]}"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
