# TODO configure FZF with an environment variable called FZF_HELP_OBTS
# TODO READLINE_LINE does not work with zsh
# append_line does not work with zsh (as it depends on  READLINE_LINE)

fzf_help() {
    option=$(echo $READLINE_LINE | _get_command | fzf_select_cli_option)
    append_line "$option"
}

_get_command() {
    sed "s/\( -\).*$//"
}

fzf_select_cli_option() {
    local cmd 

    if [[ -p /dev/stdin ]]; then
        cmd="$(cat -)"
    else
        cmd="${@}"
    fi
    
    cli_options=$(get_cli_options "$cmd")
    fzf_preview="echo \"$cli_options\" | bat_cli_option \"$cmd\" {}; [ {q} ];"

    echo "$cli_options" | _remove_line_number | 
    fzf --preview-window=right,75%,nowrap \
        --bind 'ctrl-a:change-preview-window(down,75%,nowrap|right,75%,nowrap)' \
        --prompt=$READLINE_LINE --preview $fzf_preview
}

_remove_line_number() {
    sed "s/^.*://g" 
}
