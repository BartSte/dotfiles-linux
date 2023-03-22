export ZSH=/usr/share/oh-my-zsh/
export DEFAULT_USER="barts"

HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.histfile

dir_zsh="$HOME/dotfiles-linux/zsh"
dir_bash="$HOME/dotfiles-linux/bash"

zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

plugins=(archlinux 
        python
	jsontools 
	gitfast 
	colored-man-pages 
	colorize 
	dirhistory)

ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

source $dir_bash/git.sh
source $dir_bash/env.sh
source $dir_bash/aliases.sh
running_wsl && source $dir_bash/wsl.sh

source $dir_zsh/functions.zsh
source $dir_zsh/settings.zsh
source $dir_zsh/bindings.zsh

save_source $HOME/dotfiles-linux/config.sh
save_source $HOME/dotfiles-secret/secret-config.sh
