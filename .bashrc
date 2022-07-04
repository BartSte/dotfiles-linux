source ~/dotfiles-linux/bash/env.sh
source ~/dotfiles-linux/bash/aliases.sh
source ~/dotfiles-linux/bash/bindings.sh

[ -f ~/dotfiles-linux/config.sh ] && source ~/dotfiles-linux/config.sh
[ -f ~/dotfiles-linux/secrect_config.sh ] && source ~/dotfiles-linux/secrect_config.sh
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if running_wsl; then
    source ~/dotfiles-linux/bash/wsl.sh
fi
