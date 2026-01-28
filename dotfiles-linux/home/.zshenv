#!/usr/bin/env zsh

zshenv() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"
    source "$HOME/dotfiles-linux/zsh/fzf.zsh"

    add_to_path "$HOME/dotfiles-linux/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" /usr/bin/vendor_perl

    export BROWSER='qutebrowser'
    export EARBUDS='30:53:C1:B8:CE:F6'
    export ESCDELAY=0
    export GPG_TTY=$(tty)
    export HEADPHONES="28:11:A5:A4:3A:CF"
    export IPDB_CONTEXT_SIZE=10
    export MANPAGER="nvim +Man!"
    export PYTHONBREAKPOINT='ipdb.set_trace'
    export SONY="AC:80:0A:C8:77:2C"
    export TIME_ZONE="Europe/Amsterdam"
    export TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
    export VI_MODE_SET_CURSOR=true
    export IP_PI=192.168.1.248
    hash nvim && export EDITOR='nvim' || unset EDITOR

    export HISTFILE=$HOME/.histfile
    export HISTSIZE=1000000000
    export SAVEHIST=100000
    export KEYTIMEOUT=1

    source ~/dotfiles-linux/zsh/fzf.zsh && _fzfenv
    export HELP_MESSAGE_RC="$HOME/dotfiles-linux/zsh/fzfhelprc.zsh"
    export FZF_OPEN_REGEX_EXTRA=$(~/dotfiles-linux/tmux/tmux-fzf-open/regex-extra)

    # Local variables
    GITHUB_PERSONAL="git@github.com-personal"
    GITHUB_WORK="git@github.com-work"
}
zshenv
