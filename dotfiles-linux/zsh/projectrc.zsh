# This file should be sourced from .zshrc. It will load extra zsh configurations
# based on the name of the current directory. This is useful for loading project
# specific configurations, for example.
reload-session() {
    setopt LOCAL_OPTIONS
    set -euo pipefail

    local this_dir=${${(%):-%x}:A:h}
    local configs="$this_dir/projectrc"
    local cwd_relative_to_home=$(sed "s|^$HOME||" <<< "$PWD")

    local config=$(realpath "${configs}/${cwd_relative_to_home}.zsh")
    local config_default=$(dirname $config)/default.zsh

    source "$config" 2>/dev/null || source "$config_default" 2>/dev/null || true
    PROJECTRC=$(sed "s|/|_|g; s|^_||" <<< "$cwd_relative_to_home")
    export PROJECTRC
}

reload-session "$@"
