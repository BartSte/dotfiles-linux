#!/usr/bin/env zsh

load_fzf() {
    # TODO: I want alt-d to paste the directory in the command line. I want tc 
    # alt-c to cd into the directory. 
    # TODO: currently, ctrl-g switches to unrestricted mode. I also want to be 
    # able to switch to back from unrestricted mode to using the .ignore file.

    _BASE_COMMAND="fd --hidden --no-ignore-vcs --ignore-file $HOME/.ignore"
    _BASE_UNRESTRICTED_COMMAND="fd --unrestricted" 
    export FZF_DEFAULT_COMMAND="$_BASE_COMMAND --type f"
    export FZF_ALT_C_COMMAND="$_BASE_COMMAND --type d"
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
    export FZF_ALT_H_COMMAND="$FZF_DEFAULT_COMMAND . $HOME"
    export FZF_ALT_D_COMMAND="$FZF_ALT_C_COMMAND . $HOME"
    export FZF_CTRL_T_UNRESTRICED_COMMAND="$_BASE_UNRESTRICTED_COMMAND --type f"
    export FZF_ALT_C_UNRESTRICTED_COMMAND="$_BASE_UNRESTRICTED_COMMAND --type d"
    export FZF_ALT_H_UNRESTRICTED_COMMAND="$_BASE_COMMAND . $HOME"
    export FZF_ALT_D_UNRESTRICTED_COMMAND="$_BASE_UNRESTRICTED_COMMAND . $HOME"

    export FZF_DEFAULT_OPTS="
        --height 49% \
        --layout=reverse \
        --preview-window=right,65%"

    _FZF_PREVIEW_OPTS_FILES='
        bat --theme=gruvbox-dark \
        --style=numbers \
        --color=always \
        --line-range :500 {}'

    _FZF_PREVIEW_OPTS_DIR='
        exa \
        -color=always \
        -icons \
        T -L 1 -a {} | head -200'

    export FZF_CTRL_T_OPTS="
        --bind 'ctrl-p:toggle-preview' \
        --bind 'ctrl-g:reload($FZF_CTRL_T_UNRESTRICED_COMMAND)' \
        --preview '$_FZF_PREVIEW_OPTS_FILES' \
        --preview-window 'hidden'"

    export FZF_ALT_H_OPTS="
        --bind 'ctrl-p:toggle-preview' \
        --bind 'ctrl-g:reload($FZF_ALT_H_UNRESTRICTED_COMMAND)' \
        --preview '$_FZF_PREVIEW_OPTS_FILES' \
        --preview-window 'hidden'"

    export FZF_ALT_C_OPTS="
        --bind 'ctrl-p:toggle-preview' \
        --bind 'ctrl-g:reload($FZF_ALT_C_UNRESTRICTED_COMMAND)' \
        --preview '$_FZF_PREVIEW_OPTS_DIR' \
        --preview-window 'hidden'"

    export FZF_ALT_D_OPTS="
        $FZF_ALT_D_OPTS \
        --bind 'ctrl-p:toggle-preview' \
        --bind 'ctrl-g:reload($FZF_ALT_D_UNRESTRICTED_COMMAND)' \
        --preview '$_FZF_PREVIEW_OPTS_FILES' \
        --preview-window 'hidden'"

    export HELP_MESSAGE_RC="$HOME/dotfiles-linux/zsh/fzfhelprc.zsh"
    export FZF_HELP_SYNTAX='help'
    export CLI_OPTIONS_CMD="ag -o --numbers -- \$RE"

    export FZF_OPEN_OPTS="--preview 'bat --theme=gruvbox-dark --color=always --line-range :500 {}' --preview-window 'hidden'"

    export FZF_OPEN_REGEX_EXTRA=$(~/dotfiles-linux/tmux/tmux-fzf-open/regex-extra)

}

zshenv() {
    source "$HOME/dotfiles-linux/zsh/bootstrap.zsh"

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

    load_fzf

}
zshenv
