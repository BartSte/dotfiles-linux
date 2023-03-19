dir_bash="$HOME/dotfiles-linux/bash"

source $dir_bash/functions.sh

save_source ~/dotfiles-linux/config.sh
save_source ~/dotfiles-secret/secret-config.sh

source $dir_bash/env.sh
source $dir_bash/aliases.sh

source $dir_bash/fzf.sh
source $dir_bash/git.sh
running_wsl && source $dir_bash/wsl.sh

source $dir_bash/bindings.sh

eval "$(oh-my-posh init bash --config ~/dotfiles/posh/gruvbox.omp.json)"
