bash=$HOME/dotfiles-linux/bash

source $bash/functions.sh

save_source ~/dotfiles-linux/config.sh
save_source ~/dotfiles-secret/secret-config.sh

source $bash/git.sh
source $bash/env.sh
source $bash/aliases.sh
source $bash/bindings.sh

running_wsl && source $bash/wsl.sh

eval "$(oh-my-posh init bash --config ~/dotfiles/posh/gruvbox.omp.json)"
