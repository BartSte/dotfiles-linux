export ZSH=/usr/share/oh-my-zsh/
export FZF_BASE=/usr/share/fzf/

VI_MODE_SET_CURSOR=true
VI_MODE_CURSOR_NORMAL=2
VI_MODE_CURSOR_VISUAL=2
VI_MODE_CURSOR_INSERT=6
VI_MODE_CURSOR_OPPEND=0

HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.histfile

dir_sh="$HOME/dotfiles-linux/sh"
dir_zsh="$HOME/dotfiles-linux/zsh"
dir_plugins=/usr/share/zsh/plugins

# TODO
# This plugin can also be used to show the git branch and is likely faster: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/branch
plugins=(
    ag
    colored-man-pages
    colorize
    copybuffer
    copypath
    fd
    vi-mode
    # virtualenv
    )

ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
source $dir_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $dir_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $dir_plugins/fzf-tab-git/fzf-tab.zsh

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

