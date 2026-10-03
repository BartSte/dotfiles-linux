_zshrc_plugins() {
    local dir_plugins=$1
    save-source "$dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
}

_zshrc_syntax_highlighting() {
    local dir_plugins=$1
    # zsh-syntax-highlighting must be sourced after all other widgets/plugins.
    save-source "$dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
}

_zshrc_config() {
    local dir_zsh=$1
    local files=(
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
        source "$dir_zsh/$file"
    done
}

_zshrc_p10k() {
    if [[ -f "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        source "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme"
    elif [[ -f "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        source "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"
    fi
    save-source "$HOME/.p10k.zsh" # must be after _zshrc_load
}

# Load zsh config. Loading ~/.p10k.zsh must not be loaded with
# `set -euo pipefail`, therefore it is excluded from _zshrc_load.
zshrc() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"

    _zshrc_config "$HOME/dotfiles-linux/zsh"
    local plugin_dir
    if [ -d "/usr/share/zsh/plugins" ]; then
        plugin_dir="/usr/share/zsh/plugins"
    else
        plugin_dir="/usr/share"
    fi
    _zshrc_plugins "$plugin_dir"
    _zshrc_p10k
    _zshrc_syntax_highlighting "$plugin_dir"
}

zshrc
