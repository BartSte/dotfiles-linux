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
        source "$dir_zsh/$file"
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

    _zshrc_config "$HOME/dotfiles-linux/zsh"
    if [ -d "/usr/share/zsh/plugins" ]; then
        _zshrc_plugins "/usr/share/zsh/plugins"
    else
        _zshrc_plugins "/usr/share"
<<<<<<< HEAD
=======
=======
<<<<<<< HEAD
    else
        _zshrc_plugins "/usr/share"
=======
    elif [ -d "usr/share/zsh" ]; then
        _zshrc_plugins "usr/share/zsh"
    else
        echo "ERROR: Zsh plugins directory not found" >&2
        exit 1
>>>>>>> fd77d827a5e2abd11219557a647394062b344732
>>>>>>> 2149ab82aaeecc67c6e504d71e46244c2c3ffe83
>>>>>>> 48d9350a532fdecb8224f3e02e84ddc6cf9a5930
    fi
    _zshrc_p10k
}

zshrc "$@"
export PATH="$HOME/.npm-global/bin:$PATH"

