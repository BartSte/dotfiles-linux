# Return the name of the tmux session. If tmux is not running, return an the
# name of the current working directory. The tmux session is preferred when
# possible, as this gives the same settings for the whole session, even when
# you are changing your current working directory.
get_project_name() {
    if [ -n "${TMUX:-}" ]; then
        tmux display-message -p '#S'
    else
        basename $(pwd)
    fi
}
