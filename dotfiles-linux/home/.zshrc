if ! is_running ai; then

    . "$HOME"/dotfiles-linux/zsh/.zshrc

    if is_running raspberry; then
        save-source "$HOME"/dotfiles-pi/.zshrc
    fi

fi

# Added by garmin-connect-screens setup
export PATH="$HOME/.local/bin:$PATH"
