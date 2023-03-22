# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.histfile

dir_sh="$HOME/dotfiles-linux/sh"
dir_zsh="$HOME/dotfiles-linux/zsh"
dir_plugins=/usr/share/zsh/plugins

source $dir_sh/git.sh
source $dir_sh/env.sh
source $dir_sh/aliases.sh
source $dir_sh/functions.sh
running_wsl && source $dir_sh/wsl.sh

source $dir_zsh/oh-my-zsh.zsh
source $dir_zsh/settings.zsh
source $dir_zsh/bindings.zsh
source $dir_zsh/aliases.zsh
source $dir_zsh/functions.zsh
save_source $HOME/dotfiles-linux/config.sh
save_source $HOME/dotfiles-secret/secret-config.sh

source $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $dir_plugins/fzf-tab-git/fzf-tab.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
