if grep -q microsoft /proc/version; then
    source ~/.config/bash/wsl.sh
fi

source ~/dotfiles-linux/bash/env.sh
source ~/dotfiles-linux/bash/aliases.sh
source ~/dotfiles-linux/bash/settings.sh
source ~/dotfiles-linux/bash/bindings.sh

[ -f ~/dotfiles/config.sh ] && source ~/dotfiles/config.sh
[ -f ~/dotfiles/secret_config.sh ] && source ~/dotfiles/secret_config.sh
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

