# Only source the file if it exists. If it does not exist print a warning
# to stderr.
save_source() {
    local file=$1
    if [ -f "$file" ]; then
        source $file
    else
        echo "WARNING: $file does not exist" >&2
    fi
}

dir_zsh=$HOME/dotfiles-linux/zsh
dir_plugins=/usr/share/zsh/plugins

save_source $dir_zsh/p10k_init.zsh  # must stay at the top

save_source $HOME/.dotfiles_config.sh

save_source $dir_zsh/git.zsh
running_wsl && . $dir_zsh/wsl.zsh
save_source $dir_zsh/settings.zsh
save_source $dir_zsh/aliases.zsh
save_source $dir_zsh/functions.zsh
save_source $dir_zsh/completion.zsh
save_source $dir_zsh/vi-mode.zsh

save_source $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
save_source $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
save_source $dir_zsh/bindings.zsh

save_source $HOME/dotfiles-linux/tmux/sessionrc.zsh

save_source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
save_source ~/.p10k.zsh  # must stay at the bottom
