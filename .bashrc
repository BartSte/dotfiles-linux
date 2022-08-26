[ -f ~/dotfiles-linux/config.sh ] && source ~/dotfiles-linux/config.sh
[ -f ~/dotfiles-secret/secret-config.sh ] && source ~/dotfiles-secret/secret-config.sh
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

source ~/dotfiles-linux/bash/env.sh
source ~/dotfiles-linux/bash/fzf.bash
source ~/dotfiles-linux/bash/aliases.sh
source ~/dotfiles-linux/bash/bindings.sh
running_wsl && source ~/dotfiles-linux/bash/wsl.sh

OPENER=mimeo
[[ -e "/usr/share/fzf/fzf-extras.bash" ]] && source /usr/share/fzf/fzf-extras.bash

