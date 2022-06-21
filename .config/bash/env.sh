export PROMPT_COMMAND='echo -en "\033]0;$(hostname) @ $(pwd)\a"'
export PS0="\e[2 q"
# export PS1="\\$ \[$(tput sgr0)\]\[\033[38;5;10m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;6m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"
export PS1="\\$ \[$(tput sgr0)\]\[\033[38;5;10m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;14m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"

export GPG_TTY=$(tty)
export EDITOR='vim'

export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file ~/.ignore -t f '' ."
export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border"

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS='--preview "batcat --style=numbers --color=always --line-range :500 {}"'

export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file ~/.ignore -t d '' ."
command -v tree > /dev/null && export FZF_ALT_C_OPTS='--preview "tree -C {} | head -200"'

export FZF_COMPLETION_TRIGGER=""
export FZF_COMPLETION_OPTS='--border --info=inline'

_fzf_compgen_path() {
  fdfind --hidden --follow --max-depth 4 --ignore-file ~/.ignore . "$1"
}

_fzf_compgen_dir() {
  fdfind --type d --hidden --follow --max-depth 4 --ignore-file ~/.ignore . "$1"
}
