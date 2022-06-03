export PROMPT_COMMAND='echo -en "\033]0;$(hostname) @ $(pwd)\a"'
export PS0="\e[2 q"
export PS1="\[\033[38;5;201m\]\\$\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;51m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;172m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"

export GPG_TTY=$(tty)
export EDITOR='vim'

export FZF_CTRL_T_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file ~/.ignore -t f '' ."
export FZF_CTRL_T_OPTS='--preview "batcat --style=numbers --color=always --line-range :500 {}"'

export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file ~/.ignore -t d '' ."
command -v tree > /dev/null && export FZF_ALT_C_OPTS='--preview "tree -C {} | head -200"'

export FZF_COMPLETION_TRIGGER=""
export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border"
