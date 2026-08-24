#!/usr/bin/env zsh

zshenv() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"

    normalize_path
    add_to_path "$HOME/.npm-global/bin" "$HOME/dotfiles-arch/bin" "$HOME/dotfiles-pi/bin" "$HOME/dotfiles-linux/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" /usr/bin/vendor_perl

    export BROWSER='open'
    export LINBROWSER='qutebrowser'
    export ESCDELAY=0
    export IPDB_CONTEXT_SIZE=10
    export MANPAGER="nvim +Man!"
    export PYTHONBREAKPOINT='ipdb.set_trace'
    export TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
    hash nvim 2>/dev/null && export EDITOR='/usr/sbin/nvim' || unset EDITOR
}
zshenv

if [[ -r /proc/device-tree/model && "$(</proc/device-tree/model)" == *"Raspberry Pi"* ]]; then
    save-source "$HOME/dotfiles-pi/.zshenv"
fi
