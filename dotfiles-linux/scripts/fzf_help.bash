_fzf_help() {
    #TODO improve scroll -> apply better regex instead of literal search
    program=$READLINE_LINE
    scroll=0
    line_number=5
    ag_regex="(?<=[^\'\"\`])--([a-zA-Z0-9\-\=\[\]\.\,\%]*)(?=\s{2,}|\n| <)"
    builtin typeset READLINE_LINE_NEW="$(
        command $program --help|
            ag --only-matching -- "$ag_regex"|
            fzf --preview-window=right,75% --preview ' \ 
                program=$READLINE_LINE;
                regex=''s/\:.*$//g'';
                number="$($program --help | ag --numbers -Q -- {} | head -1 | sed $regex)"; 
                $program --help | bat -f -p -H $number --theme Dracula | ag -B 25 -A 500 -Q -- {}'
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
