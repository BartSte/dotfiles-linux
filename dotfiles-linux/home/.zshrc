_zshrc_plugins() {
    local dir_plugins=$1
    save-source "$dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    save-source "$dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
}

_zshrc_config() {
    local dir_zsh=$1
    local files=(
        "p10k_init.zsh" # must be first
        "git.zsh"
        "wsl.zsh"
        "fzf.zsh"
        "settings.zsh"
        "aliases.zsh"
        "functions.zsh"
        "completion.zsh"
        "vi-mode.zsh"
        "bindings.zsh"
        "projectrc.zsh")

    save-source "$HOME/.dotfiles_config.sh"
    for file in "${files[@]}"; do
        save-source "$dir_zsh/$file" || echo "An error in $file" >&2
    done
}

_zshrc_p10k() {
    save-source "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme"
    save-source "$HOME/.p10k.zsh" # must be after _zshrc_load
}

# Load zsh config. Loading ~/.p10k.zsh must not be loaded with
# `set -euo pipefail`, therefore it is excluded from _zshrc_load.
zshrc() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"

    [[ $1 == "-v" || $1 == "--verbose" ]] && _zshrc_verbose=true

    _zshrc_config "$HOME/dotfiles-linux/zsh"
    _zshrc_plugins /usr/share/zsh/plugins
    _zshrc_p10k
}

zshrc "$@"
