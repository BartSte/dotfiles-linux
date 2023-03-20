HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

dir_zsh="$HOME/dotfiles-linux/zsh"
dir_bash="$HOME/dotfiles-linux/bash"

source $dir_bash/env.sh
source $dir_bash/aliases.sh

source $dir_zsh/settings.zsh
source $dir_zsh/fzf.zsh
source $dir_zsh/bindings.zsh
