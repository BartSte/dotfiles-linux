export PROMPT_COMMAND='echo -en "\033]0;$(hostname) @ $(pwd)"'
export PS0="\e[2 q"
export PS1="\\$ \[$(tput sgr0)\]\[\033[38;5;14m\]\W\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;10m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]>\[$(tput sgr0)\]"

export GPG_TTY=$(tty)
export EDITOR='vim'

export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore"
export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border"

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS='--preview "bat --theme=gruvbox-dark --style=numbers --color=always --line-range :500 {}"'

export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore -t d"
command -v exa > /dev/null && export FZF_ALT_C_OPTS='--preview "exa --icons -T -a {} | head -200"'

export FZF_COMPLETION_TRIGGER=""
export FZF_COMPLETION_OPTS='--border --info=inline'

export HEADPHONES='28:11:A5:A4:3A:CF'

_fzf_compgen_path() {
  fd --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

_fzf_help()
{
        program=$READLINE_LINE
        ag_regex="\-\-([.*\S]+)"
        sed_regex1='s/\[$//g'
        sed_regex2='s/\]$//g'
        builtin typeset READLINE_LINE_NEW="$(
            command $program --help|
                ag -o $ag_regex|
                sed $sed_regex1|
                sed $sed_regex2|
                env fzf -m --preview "$program --help|bat"
        )"

        if
                [[ -n $READLINE_LINE_NEW ]]
        then
                builtin bind '"\er": redraw-current-line'
                builtin bind '"\e^": magic-space'
                READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${READLINE_LINE_NEW}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
                READLINE_POINT=$(( READLINE_POINT + ${#READLINE_LINE_NEW} ))
        else
                builtin bind '"\er":'
                builtin bind '"\e^":'
        fi
}

builtin bind -x '"\C-x1": __fzf_select_dir'
builtin bind '"\C-a": "\C-x1\e^\er "'
