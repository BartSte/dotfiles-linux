# This file can be sourced from .zshrc. It will load zsh configurations for
# specific tmux sessions, based on the session name.

if [[ -z "$TMUX" ]]; then
    return
fi

dir=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
name=$(tmux display-message -p '#S')
winpyprojects=(navigation fc-sonar-server)

if [[ "$name" == "snapshot" ]]; then
    source $dir/snapshotrc.zsh

# If a project is a python project that is developed for windows, then loading
# the winpyprojectrc.zsh file is nice as it allows you to call the python
# windows interpreter from wsl. See the wpy executable for more info.
elif [[ " ${winpyprojects[@]} " =~ " $name " ]]; then
    source $dir/winpyprojectrc.zsh
fi
