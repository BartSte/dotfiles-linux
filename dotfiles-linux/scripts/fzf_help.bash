_fzf_help()
{
        program=$READLINE_LINE
        ag_regex="--[^=\ ]*[=\ ]"
        builtin typeset READLINE_LINE_NEW="$(
            command $program --help|
                ag -o -- "$ag_regex"|
                env fzf -m --ansi --preview "$program --help|bat -f --theme Dracula --highlight-line 4"
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
