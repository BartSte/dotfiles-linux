if [[ -z ${CODEX_THREAD_ID:-}${CLAUDE_CODE_SESSION:-} ]]; then
    # Powerlevel10k's instant prompt must run before the rest of the config.
    source "$HOME/dotfiles-linux/zsh/p10k_init.zsh"
    source "$HOME/dotfiles-linux/zsh/.zshrc"

    if [[ -r /proc/device-tree/model && "$(</proc/device-tree/model)" == *"Raspberry Pi"* ]]; then
        save-source "$HOME/dotfiles-pi/.zshrc"
    fi
fi

# Added by garmin-connect-screens setup
export PATH="$HOME/.local/bin:$PATH"
# Added by garmin-connect-screens setup
if command -v connect-iq-sdk-manager >/dev/null 2>&1; then export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"; fi
