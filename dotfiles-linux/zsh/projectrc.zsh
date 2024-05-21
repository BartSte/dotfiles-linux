# This file should be sourced from .zshrc. It will load extra zsh configurations
# based on the name of the current directory. This is useful for loading project
# specific configurations.
reload-session() {
    setopt LOCAL_OPTIONS
    set -euo pipefail

    [[ $1 == "-v" || $1 == "--verbose" ]] && _zshrc_verbose=true

    local dir="$HOME/dotfiles-linux/zsh/projectrc"
    source "$dir/helpers.zsh"

    PROJECTRC=$(get_project_name)
    export PROJECTRC

    _zshrc_log "Project name: $PROJECTRC"
    if [[ "$PROJECTRC" == "snapshot" ]]; then
        _zshrc_log "Snapshot project detected. Loading snapshotrc.zsh"
        save-source "$dir/snapshotrc.zsh"
    fi

    if [[ "$PROJECTRC" == "kmonad-tray" ]]; then
        _zshrc_log "kmonad-tray project detected. Loading kmonad-trayrc.zsh"
        save-source "$dir/kmonad-trayrc.zsh"
    fi

    # If a project is a python project that is developed for windows, then
    # loading the winpyprojectrc.zsh file is nice as it allows you to call the
    # python windows interpreter from wsl. See the wpy executable for more
    # info. Also, the name is changed to winpyprojectrc to group their
    # configurations.
    local winpyprojects=(
        automated-reporting
        fc-deckcam-software
        fc-sonar-server
        navigation
        quay-detector
        fcissgui
        fcisscore
    )
    if [[ " ${winpyprojects[@]} " =~ " $PROJECTRC " ]]; then
        PROJECTRC="winpyproject"
        _zshrc_log "Windows python project detected. Loading winpyprojectrc.zsh"
        save-source "$dir/winpyprojectrc.zsh"
    fi
}
reload-session "$@"
