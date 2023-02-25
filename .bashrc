[ -f ~/dotfiles-linux/config.sh ] && source ~/dotfiles-linux/config.sh
[ -f ~/dotfiles-secret/secret-config.sh ] && source ~/dotfiles-secret/secret-config.sh


cd ~/dotfiles-linux/bash
source env.sh
source git_functions.bash
source aliases.sh
source fzf.bash
source bindings.sh
source posh.bash
running_wsl && source wsl.sh
source functions.bash
cd - > /dev/null

eval "$(oh-my-posh init bash --config ~/dotfiles/posh/gruvbox.omp.json)"

[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
[ -f  ~/clones/fzf-tab-completion/bash/fzf-bash-completion.sh ] && source ~/clones/fzf-tab-completion/bash/fzf-bash-completion.sh
