#!/usr/bin/env zsh


zshenv() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"
    source "$HOME/dotfiles-linux/zsh/fzf.zsh"

    add_to_path "$HOME/dotfiles-linux/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" /usr/bin/vendor_perl

    export BROWSER='qutebrowser'
    export WSLBROWSER='/mnt/c/Program Files/qutebrowser/qutebrowser.exe'
    hash nvim && export EDITOR='nvim'
    export GPG_TTY=$(tty)
    export EARBUDS='30:53:C1:B8:CE:F6'
    export ESCDELAY=0
    export MANPAGER="nvim +Man!"
    export TIME_ZONE="Europe/Amsterdam"
    export HEADPHONES="28:11:A5:A4:3A:CF"
    export SONY="AC:80:0A:C8:77:2C"
    export PYTHONBREAKPOINT='ipdb.set_trace'
    export IPDB_CONTEXT_SIZE=10
    export TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
    export VI_MODE_SET_CURSOR=true

    export HISTFILE=$HOME/.histfile
    export HISTSIZE=1000000000
    export SAVEHIST=100000
    export KEYTIMEOUT=1

    _load_fzf
}
zshenv
