dir_zsh=$HOME/dotfiles-linux/zsh
dir_plugins=/usr/share/zsh/plugins

. $dir_zsh/p10k_init.zsh  # must stay at the top

. $HOME/.dotfiles_config.sh

rbw unlock

. $dir_zsh/git.zsh
running_wsl && . $dir_zsh/wsl.zsh
. $dir_zsh/settings.zsh
. $dir_zsh/aliases.zsh
. $dir_zsh/functions.zsh
. $dir_zsh/completion.zsh
. $dir_zsh/vi-mode.zsh
. $dir_zsh/fzf-git.sh # after fzf, before bindings

. $dir_plugins/fzf-help/fzf-help.zsh # after fzf
. $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
. $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
. $dir_zsh/bindings.zsh

. /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
. ~/.p10k.zsh  # must stay at the bottom
