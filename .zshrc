dir_sh=$HOME/dotfiles-linux/sh
dir_zsh=$HOME/dotfiles-linux/zsh
dir_plugins=/usr/share/zsh/plugins

. $dir_zsh/p10k_init.zsh  # must stay at the top

. $HOME/dotfiles-linux/config.sh
. $dir_sh/git.sh
. $dir_sh/env.sh
. $dir_sh/aliases.sh
. $dir_sh/functions.sh
running_wsl && . $dir_sh/wsl.sh

. $dir_zsh/settings.zsh
. $dir_zsh/aliases.zsh
. $dir_zsh/functions.zsh
. $dir_zsh/completion.zsh
. $dir_zsh/bw-completion.zsh
. $dir_zsh/vi-mode.zsh
. $dir_zsh/fzf.zsh  # after vi-mode
. $dir_zsh/bindings.zsh  # after fzf

. $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
. $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
. /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme


. ~/.p10k.zsh  # must stay at the bottom

