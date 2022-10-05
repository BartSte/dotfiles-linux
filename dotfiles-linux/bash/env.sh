export PROMPT_COMMAND='echo -en "\033]0;$(hostname) @ $(pwd)"'
export PS0="\e[2 q"
export PS1="\\$ \[$(tput sgr0)\]\[\033[38;5;14m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;10m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"

export GPG_TTY=$(tty)
export EDITOR='nvim'

export HEADPHONES='28:11:A5:A4:3A:CF'

