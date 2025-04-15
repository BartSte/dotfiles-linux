# This file should be sourced from .zshrc. It will load extra zsh configurations
# based on the name of the current directory. This is useful for loading project
# specific configurations.
reload-session() {
    setopt LOCAL_OPTIONS
    set -euo pipefail

    local dir="$HOME/dotfiles-linux/zsh/projectrc"
    source "$dir/helpers.zsh"

    PROJECTRC=$(get_project_name)
    export PROJECTRC

    # A python project enables the following:
    # - call the python windows python interpreter from wsl. See the wpy
    # executable for more info.
    # - load aider python conventions
    local pyproject=(
        bartste-prompts
        khalorg
        pygeneral
    )
    [[ " ${pyproject[@]} " =~ " $PROJECTRC " ]] && PROJECTRC="pyproject"

    # Same as pyproject but now it loads configurations for projects at Fleet
    # Robotics
    local fr_pyproject=(
        automated-reporting
        fc-data-client
        fc-deckcam-software
        fc-deckcam-software
        fc-pipelines
        fc-report
        fc-report
        fc-sonar-server
        fcbuild
        fcenums
        fcisscore
        fcissgui
        fctools
        fleet-inspector
        fr-pyqt
        fr_camera_module
        fr_message_broker
        fr_qt_material
        isssdk
        navigation
        navigation310
        orders-operations-reports-database
        quay-detector
        software-engineering-general
        supervisor-software
    )
    [[ " ${fr_pyproject[@]} " =~ " $PROJECTRC " ]] && PROJECTRC="fr_pyproject"

    # Try to activate a python virtual environment if it exists in a `.venv`
    # directory.
    if [[ -f .venv/bin/activate ]]; then
        source .venv/bin/activate
    fi

    # Load the project specific zsh configuration file if it exists.
    if [[ -f "$dir/projects/$PROJECTRC.zsh" ]]; then
        source "$dir/projects/$PROJECTRC.zsh"
    fi

}

reload-session "$@"
