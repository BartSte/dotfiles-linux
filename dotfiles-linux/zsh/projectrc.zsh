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
        fcenums
        fc-report
        fctools
        fcbuild
        supervisor-software
        fc-data-client
        fc-report
    )
    [[ " ${winpyprojects[@]} " =~ " $PROJECTRC " ]] && PROJECTRC="winpyproject"

    # Load the project specific zsh configuration file if it exists.
    . "$dir/$PROJECTRC.zsh" 2>/dev/null || true
}
reload-session "$@"
