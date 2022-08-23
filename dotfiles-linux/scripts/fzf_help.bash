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
    _get_line_number+='[ {q} == "##" ] && number=0;'

    _get_scroll_number='half_page=$(($FZF_PREVIEW_LINES / 2));'
    _get_scroll_number+='scroll=$(($number-$half_page));'
    _get_scroll_number+='scroll=$(($scroll > 0 ? $scroll : 0));'

    _write_to_stdout='$_FZF_HELP_COMMAND --help | bat -f -p -H $number -r $scroll: --theme Dracula;'

    export _FZF_HELP_PREVIEW_OPTS="$_get_line_number $_get_scroll_number $_write_to_stdout"
    export _FZF_HELP_OTHER_OPTS='--preview-window=right,75%' 
    export _FZF_HELP_HEADER='Type ## for full page view'
}

_fzf_help() {
    regex_get_command='s/\( -\).*$//'
    export _FZF_HELP_COMMAND=$(echo $READLINE_LINE | sed "$regex_get_command")
    builtin typeset READLINE_LINE_NEW=$(
        regex_remove_line_number='s/^.*://g';
        export _FZF_HELP_RESULTS=$("$_FZF_HELP_COMMAND" --help | 
                                   ag -o --numbers -- "$_FZF_HELP_REGEX");
        echo "$_FZF_HELP_RESULTS" | sed "$regex_remove_line_number" | 
             fzf $_FZF_HELP_OTHER_OPTS --preview "$_FZF_HELP_PREVIEW_OPTS" --header="$_FZF_HELP_HEADER"
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
