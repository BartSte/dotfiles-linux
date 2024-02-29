# Load zsh config with set -euo pipefail
_zshrc_load() {
    setopt LOCAL_OPTIONS
    set -euo pipefail

    local dir_zsh=$1
    local dir_plugins=$2

    save-source "$HOME/.dotfiles_config.sh"

    save-source "$dir_zsh/git.zsh"
    running_wsl && source "$dir_zsh/wsl.zsh"
    save-source "$dir_zsh/settings.zsh"
    save-source "$dir_zsh/aliases.zsh"
    save-source "$dir_zsh/functions.zsh"
    save-source "$dir_zsh/completion.zsh"
    save-source "$dir_zsh/vi-mode.zsh"

    save-source "$dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    save-source "$dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    save-source "$dir_zsh/bindings.zsh"

    save-source "$dir_zsh/sessionrc/main.zsh"

    save-source "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme"
}

# Load zsh config. Loading p10k_init.zsh should not be loaded with
# `set -euo pipefail`, therefore it is excluded from _zshrc_load.
reload() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"

    local dir_zsh=$HOME/dotfiles-linux/zsh
    local dir_plugins=/usr/share/zsh/plugins
    save-source "$dir_zsh/p10k_init.zsh" # must be before _zshrc_load
    _zshrc_load "$dir_zsh" "$dir_plugins"
    save-source "$HOME/.p10k.zsh" # must be after _zshrc_load
}

reload
