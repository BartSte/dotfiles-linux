fzf_help() {
    local cmd
    cmd=$(_get_command $READLINE_LINE)
    option=$(_fzf_get_option $cmd)
    _write_line $option
}

_get_command() {
    echo $1 | sed 's/\( -\).*$//'
}

_fzf_get_option() {
    local cmd
    cmd=$1

    export _FZF_HELP_RESULTS=$(_get_options $cmd);
    _fzf_select_option $cmd
}

_get_options() {
    $1 --help | ag -o --numbers -- "$_FZF_HELP_REGEX"
}

_fzf_select_option() {
    export _FZF_HELP_COMMAND=$1

    echo "$_FZF_HELP_RESULTS" | 
    sed "s/^.*://g" | 
    fzf $_FZF_HELP_OTHER_OPTS --prompt="$READLINE_LINE" --preview "$_FZF_HELP_PREVIEW_OPTS" 
}

_write_line() {
    READLINE_LINE_NEW=$1
    if
        [[ -n $READLINE_LINE_NEW ]]
    then
        builtin bind '"\er": redraw-current-line'
        builtin bind '"\e^": magic-space'
        READLINE_LINE_NEW+=" "
        READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${READLINE_LINE_NEW}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
        READLINE_POINT=$(( READLINE_POINT + ${#READLINE_LINE_NEW} ))
    else
        builtin bind '"\er":'
        builtin bind '"\e^":'
    fi
}

_make_fzf_help_regex() {
    _regex_head='?<=[^''"`]'
    _regex_tail='?=\s{2,}|(?<=[^\.])\n| <'
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
    _get_line_number+='[ {q} ]; [ -z $number ] && number=0;'  # Hack, without {q} the preview window is always blank.

    _get_scroll_number='half_page=$(($FZF_PREVIEW_LINES / 2));'
    _get_scroll_number+='scroll=$(($number-$half_page));'
    _get_scroll_number+='scroll=$(($scroll > 0 ? $scroll : 0));'

    _write_to_stdout='printf "\033[2J";'  # Clear screen
    _write_to_stdout+='$_FZF_HELP_COMMAND --help | bat -f -p --wrap never -H $number -r $scroll: --theme Dracula;'

    export _FZF_HELP_PREVIEW_OPTS="$_get_line_number $_get_scroll_number $_write_to_stdout"
    export _FZF_HELP_OTHER_OPTS='--preview-window=right,75%,nowrap --bind ctrl-a:change-preview-window(down,75%,nowrap|right,75%,nowrap) '
}

_make_fzf_help_regex
_make_fzf_help_opts
