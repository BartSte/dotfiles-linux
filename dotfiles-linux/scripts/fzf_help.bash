_regex_head='(?<=[^''\"\`])'
_regex_tail='(?=\s{2,}|\n| <)'
_allowed_symbols='\-\=\[\]\.\,\%'
_allowed_letters_and_numbers='a-zA-Z0-9'
export _FZF_HELP_REGEX="$_regex_head--([$_allowed_letters_and_numbers]+[$_allowed_letters_and_numbers$_allowed_symbols]*)$_regex_tail"

_get_line_number='regex="s/\:.*$//g"; number="$($_FZF_HELP_COMMAND --help | ag --numbers -Q -- {} | head -1 | sed $regex)";'
_highlight_line='$_FZF_HELP_COMMAND --help | bat -f -p -H $number --theme Dracula | ag -B 25 -A 500 -Q -- {}'
export _FZF_HELP_PREVIEW_OPTS="$_get_line_number $_highlight_line"
export _FZF_HELP_OTHER_OPTS="--preview-window=right,75%" 

_fzf_help() {
    #TODO improve scroll -> apply better regex instead of literal search
    export _FZF_HELP_COMMAND=$(echo "$READLINE_LINE" | sed 's/\( -\).*$//')
    builtin typeset READLINE_LINE_NEW="$(
        $_FZF_HELP_COMMAND --help|
        ag --only-matching -- "$_FZF_HELP_REGEX"|
        fzf "$_FZF_HELP_OTHER_OPTS" --preview "$_FZF_HELP_PREVIEW_OPTS"
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

