if ! is_running ai; then

    . "$HOME"/dotfiles-linux/zsh/.zshrc

    if is_running raspberry; then
        save-source "$HOME"/dotfiles-pi/.zshrc
    fi

fi

# OpenClaw Completion
source "/home/barts/.openclaw/completions/openclaw.zsh"
