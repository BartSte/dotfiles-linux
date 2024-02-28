# Source a file if it exists, otherwise print a warning.
save-source() {
    local file=$1
    if [ -f "$file" ]; then
        source $file
    else
        echo "WARNING: $file does not exist" >&2
    fi
}

reload() {
    local dir_zsh=$HOME/dotfiles-linux/zsh
    local dir_plugins=/usr/share/zsh/plugins

    save-source $dir_zsh/p10k_init.zsh  # must stay at the top

    save-source $HOME/.dotfiles_config.sh

    save-source $dir_zsh/git.zsh
    running_wsl && . $dir_zsh/wsl.zsh
    save-source $dir_zsh/settings.zsh
    save-source $dir_zsh/aliases.zsh
    save-source $dir_zsh/functions.zsh
    save-source $dir_zsh/completion.zsh
    save-source $dir_zsh/vi-mode.zsh

    save-source $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    save-source $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    save-source $dir_zsh/bindings.zsh

    save-source $dir_zsh/sessionrc/main.zsh

    save-source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
    save-source ~/.p10k.zsh  # must stay at the bottom
}
reload
