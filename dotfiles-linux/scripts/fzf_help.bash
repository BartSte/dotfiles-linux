_get_line_number='regex="s/\:.*$//g"; number="$($_FZF_HELP_COMMAND --help | ag --numbers -Q -- {} | head -1 | sed $regex)";'
_highlight_line='$_FZF_HELP_COMMAND --help | bat -f -p -H $number --theme Dracula | ag -B 25 -A 500 -Q -- {}'

export _FZF_HELP_REGEX='(?<=[^''\"\`])--([a-zA-Z0-9\-\=\[\]\.\,\%]*)(?=\s{2,}|\n| <)'
export _FZF_HELP_OPTS="--preview-window=right,75%" 
export _FZF_HELP_PREVIEW_OPTS="$_get_line_number $_highlight_line"

builtin bind -x '"\C-x1": __fzf_select_dir'
builtin bind '"\C-a": "\C-x1\e^\er "'

_fzf_help() {
    #TODO improve scroll -> apply better regex instead of literal search
    export _FZF_HELP_COMMAND=$(echo "$READLINE_LINE" | sed 's/\( -\).*$//')
    builtin typeset READLINE_LINE_NEW="$(
        $_FZF_HELP_COMMAND --help|
        ag --only-matching -- "$_FZF_HELP_REGEX"|
        fzf "$_FZF_HELP_OPTS" --preview "$_FZF_HELP_PREVIEW_OPTS"
    )"
    _write_line
}

_write_line() {
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

