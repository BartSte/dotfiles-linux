session_name() {
    if [[ "$TMUX" ]]; then
        # Use the name of the current tmux session.
        tmux display-message -p '#S'
    else
        # Use the name of the current directory.
        basename $PWD
    fi
}
