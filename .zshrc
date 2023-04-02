dir_sh=$HOME/dotfiles-linux/sh
dir_zsh=$HOME/dotfiles-linux/zsh
dir_plugins=/usr/share/zsh/plugins

source $dir_zsh/p10k_init.zsh  # must stay at the top

source $dir_sh/git.sh
source $dir_sh/env.sh
source $dir_sh/aliases.sh
source $dir_sh/functions.sh
running_wsl && source $dir_sh/wsl.sh

source $dir_zsh/settings.zsh
source $dir_zsh/aliases.zsh
source $dir_zsh/functions.zsh
source $dir_zsh/completion.zsh
source $dir_zsh/vi-mode.zsh
source $dir_zsh/fzf.zsh  # after vi-mode
source $dir_zsh/bindings.zsh  # after fzf
save_source $HOME/dotfiles-linux/config.sh
save_source $HOME/dotfiles-secret/secret-config.sh

source $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme


source ~/.p10k.zsh  # must stay at the bottom

