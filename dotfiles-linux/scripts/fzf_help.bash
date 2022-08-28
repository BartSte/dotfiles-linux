fzf_help() {
    option=$(echo $READLINE_LINE | get_command | fzf_get_option) 
    write_line $option
}

get_command() {
    sed "s/\( -\).*$//"
}

fzf_get_option() {
    local cmd options
    cmd="$(cat -)"
    options=$(_get_options $cmd);
    _fzf_select_option "$cmd" "$options"
}

_get_options() {
    local cmd regex
    cmd=$@
    regex=$(_regex_get_options)
    $cmd --help | ag --only-matching --numbers -- "$regex"
}

_regex_get_options() {
    local HEAD TAIL OBLIGATORY_CHARS ALLOWED_SYMBOLS 
    local ALLOWED_LETTERS_AND_NUMBERS RESULT

    HEAD='?<=[^''"`]'
    TAIL='?=\s{2,}|(?<=[^\.])\n| <'
    OBLIGATORY_CHARS='--'
    ALLOWED_SYMBOLS='\[\]\-\=\.\,\%'
    ALLOWED_LETTERS_AND_NUMBERS='a-zA-Z0-9'

    RESULT="($HEAD)"
    RESULT+="($OBLIGATORY_CHARS)"
    RESULT+="([$ALLOWED_LETTERS_AND_NUMBERS]+"
    RESULT+="[$ALLOWED_LETTERS_AND_NUMBERS$ALLOWED_SYMBOLS]*)"
    RESULT+="($TAIL)"

    echo "$RESULT"
}

_fzf_select_option() {
    local regex_remove_line_number fzf_options

    export _FZF_HELP_COMMAND=$1
    export _FZF_HELP_RESULTS=$2

    regex_remove_line_number="s/^.*://g" 
    fzf_options='--preview-window=right,75%,nowrap '
    fzf_options+='--bind ctrl-a:change-preview-window(down,75%,nowrap|right,75%,nowrap) '

    echo "$options" | 
    sed $regex_remove_line_number| 
    fzf $fzf_options --prompt="$READLINE_LINE" --preview "$_FZF_HELP_PREVIEW_OPTS"
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
}

write_line() {
    READLINE_LINE_NEW=$@
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

_make_fzf_help_opts
