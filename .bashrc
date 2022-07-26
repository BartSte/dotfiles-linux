[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f ~/dotfiles-linux/config.sh ] && source ~/dotfiles-linux/config.sh
[ -f ~/dotfiles-secret/secret-config.sh ] && source ~/dotfiles-secret/secret-config.sh

source ~/dotfiles-linux/bash/env.sh
source ~/dotfiles-linux/bash/aliases.sh
source ~/dotfiles-linux/bash/bindings.sh
running_wsl && source ~/dotfiles-linux/bash/wsl.sh

