cd ~/dotfiles-linux/bash
source functions.sh
save_source ~/dotfiles-linux/config.sh
save_source ~/dotfiles-secret/secret-config.sh

source env.sh
source aliases.sh
source bindings.sh

source fzf.sh
source git.sh
running_wsl && source wsl.sh
cd - > /dev/null

eval "$(oh-my-posh init bash --config ~/dotfiles/posh/gruvbox.omp.json)"
