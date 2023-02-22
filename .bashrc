[ -f ~/dotfiles-linux/config.sh ] && source ~/dotfiles-linux/config.sh
[ -f ~/dotfiles-secret/secret-config.sh ] && source ~/dotfiles-secret/secret-config.sh

pushd . > /dev/null
cd ~/dotfiles-linux/bash
source env.sh
source aliases.sh
source fzf.bash
source bindings.sh
running_wsl && source wsl.sh
popd > /dev/null

[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
[ -f  ~/clones/fzf-tab-completion/bash/fzf-bash-completion.sh ] && source ~/clones/fzf-tab-completion/bash/fzf-bash-completion.sh
