fzf_help() {
    option=$(echo $READLINE_LINE | get_command | fzf_select_cli_option) 
    write_line $option
}

get_command() {
    sed "s/\( -\).*$//"
}

fzf_select_cli_option() {
    local cmd options

    if [[ -p /dev/stdin ]]; then
        cmd="$(cat -)"
    else
        cmd="${@}"
    fi

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

    cmd="$1"
    export _FZF_HELP_RESULTS=$2

    regex_remove_line_number="s/^.*://g" 
    fzf_options='--preview-window=right,75%,nowrap '
    fzf_options+='--bind ctrl-a:change-preview-window(down,75%,nowrap|right,75%,nowrap) '

    echo "$options" | 
    sed $regex_remove_line_number| 
    fzf $fzf_options --prompt="$READLINE_LINE" --preview "bat_highlight {} $cmd; [ {q} ];"
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
