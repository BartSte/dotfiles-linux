if [[ -z ${CODEX_THREAD_ID:-}${CLAUDE_CODE_SESSION:-} ]]; then
    # Powerlevel10k's instant prompt must run before the rest of the config.
    source "$HOME/dotfiles-linux/zsh/p10k_init.zsh"
    source "$HOME/dotfiles-linux/zsh/.zshrc"

    if [[ -r /proc/device-tree/model && "$(</proc/device-tree/model)" == *"Raspberry Pi"* ]]; then
        save-source "$HOME/dotfiles-pi/.zshrc"
    fi
fi
