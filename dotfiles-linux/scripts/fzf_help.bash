_make_fzf_help_regex() {
    _regex_head='?<=[^''"`]'
    _regex_tail='?=\s{2,}|\n| <'
    _obligatory_chars='--'
    _allowed_symbols='\[\]\-\=\.\,\%'
    _allowed_letters_and_numbers='a-zA-Z0-9'
    _FZF_HELP_REGEX="($_regex_head)($_obligatory_chars)"
    _FZF_HELP_REGEX+="([$_allowed_letters_and_numbers]+"
    _FZF_HELP_REGEX+="[$_allowed_letters_and_numbers$_allowed_symbols]*)"
    _FZF_HELP_REGEX+="($_regex_tail)"
    export _FZF_HELP_REGEX
}

_make_fzf_help_opts() {
    _get_line_number='number=$(echo "$_FZF_HELP_RESULTS" | ag -Q -- {} | head -1 | sed "s/:.*$//g");'
    _get_scroll_number='half_page=$(($FZF_PREVIEW_LINES / 2));scroll=$(($number-$half_page));'
    _highlight_line='$_FZF_HELP_COMMAND --help | bat -f -p -H $number --theme Dracula --line-range $(($scroll > 0 ? $scroll : 0)):500'
    export _FZF_HELP_PREVIEW_OPTS="$_regex_line_number $_get_line_number $_get_scroll_number $_highlight_line"
    export _FZF_HELP_OTHER_OPTS="--preview-window=right,75%" 
}

_fzf_help() {
    #TODO store the line numbers + search results of the first `ag` search. Use this later for highlighting and scrolling.
    export _FZF_HELP_COMMAND=$(echo $READLINE_LINE | sed 's/\( -\).*$//')
    builtin typeset READLINE_LINE_NEW=$(
        export _FZF_HELP_RESULTS=$("$_FZF_HELP_COMMAND" --help | ag --numbers --only-matching -- "$_FZF_HELP_REGEX");
        echo "$_FZF_HELP_RESULTS" | sed "s/^.*://g" | fzf "$_FZF_HELP_OTHER_OPTS" --preview "$_FZF_HELP_PREVIEW_OPTS"
    )
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

_make_fzf_help_regex
_make_fzf_help_opts
