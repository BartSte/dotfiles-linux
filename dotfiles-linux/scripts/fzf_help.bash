#!/usr/bin/bash

export FZF_HELP_OPTS='--preview-window=right,75%,nowrap '
export FZF_HELP_OPTS+='--bind ctrl-a:change-preview-window(down,75%,nowrap|right,75%,nowrap) '

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
    
    options=$(get_cli_options "$cmd")
    fzf_preview="echo \"$options\" | bat_cli_option \"$cmd\" {}; [ {q} ];"

    echo "$options" | _remove_line_number | 
    fzf $FZF_HELP_OPTS --prompt="$READLINE_LINE" --preview "$fzf_preview"
}

_remove_line_number() {
    sed "s/^.*://g" 
}

