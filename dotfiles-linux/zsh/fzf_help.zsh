# TODO configure FZF with an environment variable called FZF_HELP_OBTS

fzf_help() {
    option=$(echo $LBUFFER | _get_command | fzf_select_cli_option)
    LBUFFER="$LBUFFER$option"
    local ret=$?
    zle reset-prompt
    return $ret
}

_get_command() {
    sed "s/\( -\).*$//"
}

fzf_select_cli_option() {
    local cmd
    local options

    if [[ -p /dev/stdin ]]; then
        cmd="$(cat -)"
    else
        cmd="${@}"
    fi

    options=$(cli_options "$cmd")
    fzf_preview="echo \"$options\" | bat_cli_option \"$cmd\" {}; [ {q} ];"

    echo "$options" | _remove_line_number |
    fzf --preview-window=right,75%,nowrap \
        --height 80% \
        --bind 'ctrl-a:change-preview-window(down,75%,nowrap|right,75%,nowrap)' \
        --prompt=$BUFFER --preview $fzf_preview
}

_remove_line_number() {
    sed "s/^.*://g"
}
