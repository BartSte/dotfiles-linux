dir_sh=$HOME/dotfiles-linux/sh
dir_bash=$HOME/dotfiles-linux/bash

source $dir_sh/functions.sh

save_source ~/dotfiles-linux/config.sh
save_source ~/dotfiles-secret/secret-config.sh

source $dir_sh/git.sh
source $dir_sh/env.sh
source $dir_sh/aliases.sh
source $dir_sh/bindings.sh

source $dir_bash/aliases.bash
source $dir_bash/functions.bash

running_wsl && source $dir_sh/wsl.sh

eval "$(oh-my-posh init bash --config ~/dotfiles/posh/gruvbox.omp.json)"
