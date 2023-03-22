export ZSH=/usr/share/oh-my-zsh/

HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.histfile

dir_sh="$HOME/dotfiles-linux/sh"
dir_zsh="$HOME/dotfiles-linux/zsh"

zstyle :compinstall filename '~/.zshrc'
autoload -Uz compinit
compinit

plugins=(
    )

ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source $dir_sh/git.sh
source $dir_sh/env.sh
source $dir_sh/aliases.sh
source $dir_sh/functions.sh
running_wsl && source $dir_sh/wsl.sh

source $dir_zsh/settings.zsh
source $dir_zsh/bindings.zsh
source $dir_zsh/aliases.zsh
source $dir_zsh/functions.zsh
save_source $HOME/dotfiles-linux/config.sh
save_source $HOME/dotfiles-secret/secret-config.sh
