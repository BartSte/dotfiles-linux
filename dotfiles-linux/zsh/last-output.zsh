# Mark output in tmux without redirecting the command's terminal streams.
_last-output-start() {
    [[ -n ${TMUX:-} && -n ${TMUX_PANE:-} && -t 1 ]] || return 0
    typeset -g _last_output_pending=1
    printf '\033]133;C\007'
}

_last-output-finish() {
    setopt localoptions extendedglob
    [[ ${_last_output_pending:-0} == 1 ]] || return 0
    unset _last_output_pending
    typeset -g _last_output_ready=0
    typeset -g _last_output_text=''

    local position marked captured eol_marker
    local -a coordinates lines
    local end_line start_line index
    position=$(tmux display-message -p -t "$TMUX_PANE" '#{cursor_y} #{cursor_x}') || return 0
    coordinates=(${=position})
    end_line=$(( coordinates[1] - (coordinates[2] == 0) ))
    marked=$(tmux capture-pane -p -F -t "$TMUX_PANE" -S - -E "${coordinates[1]}") || return 0
    lines=("${(@f)marked}")

    # The O flag marks the first output line. Search from the cursor backward.
    for (( index=${#lines}; index >= 1; index-- )); do
        if [[ ${lines[index]%% *} == *O* ]]; then
            start_line=$(( coordinates[1] - (${#lines} - index) ))
            if (( start_line <= end_line )); then
                # A sentinel preserves trailing newlines through command substitution.
                captured=$(
                    tmux capture-pane -p -J -t "$TMUX_PANE" -S "$start_line" -E "$end_line" || exit
                    printf '\001'
                ) || return 0
                _last_output_text=${captured%$'\001'}
                # capture-pane adds a newline even when the command does not.
                if (( coordinates[2] != 0 )); then
                    _last_output_text=${_last_output_text%$'\n'}
                elif [[ -o promptsp && -o promptcr && ${PROMPT_EOL_MARK-'%B%S%#%s%b'} == '%B%S%#%s%b' ]]; then
                    # zsh pads partial lines with an inverse % (or # for root).
                    eol_marker='%'
                    (( EUID == 0 )) && eol_marker='#'
                    _last_output_text=${_last_output_text%${eol_marker}' '##$'\n'}
                fi
            fi
            _last_output_ready=1
            break
        fi
    done
    printf '\033]133;D\007'
    return 0
}

_copy-last-output-widget() {
    if [[ -z ${TMUX:-} ]]; then
        zle -M 'Copy last output requires tmux.'
    elif [[ ${_last_output_ready:-0} != 1 ]]; then
        zle -M 'No captured output. Run a command after loading the zsh configuration.'
    elif [[ -z $_last_output_text ]]; then
        zle -M 'The last command produced no output.'
    elif printf '%s' "$_last_output_text" | "$HOME/dotfiles-linux/bin/clip"; then
        zle -M 'Copied the last command output.'
    else
        zle -M 'Clipboard copy failed.'
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _last-output-start
add-zsh-hook precmd _last-output-finish
zle -N _copy-last-output-widget
