# This file should be sourced from .zshrc. It will load zsh configurations for
# specific tmux sessions, based on the session name. If tmux is not running,
# then use the name of the current this_directory instead.
get_name() {
    if [[ "$TMUX" ]]; then
        # Use the name of the current tmux session.
        tmux display-message -p '#S'
    else
        basename $PWD
    fi
}

name=$(get_name)
this_dir=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")

[[ "$name" == "snapshot" ]] && source $this_dir/snapshotrc.zsh

# If a project is a python project that is developed for windows, then loading
# the winpyprojectrc.zsh file is nice as it allows you to call the python
# windows interpreter from wsl. See the wpy executable for more info.
winpyprojects=(navigation fc-sonar-server)
[[ " ${winpyprojects[@]} " =~ " $name " ]] && source $this_dir/winpyprojectrc.zsh
