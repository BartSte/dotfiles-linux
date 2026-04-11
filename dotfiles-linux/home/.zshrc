if ! is_running ai; then

    . "$HOME"/dotfiles-linux/zsh/.zshrc

    if is_running raspberry; then
        save-source "$HOME"/dotfiles-pi/.zshrc
    fi

fi

# Added by garmin-connect-screens setup
export PATH="$HOME/.local/bin:$PATH"
# Added by garmin-connect-screens setup
if command -v connect-iq-sdk-manager >/dev/null 2>&1; then export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"; fi
