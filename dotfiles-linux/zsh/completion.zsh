if [[ -f /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh ]]; then
    zstyle :compinstall filename '~/.zshrc'
    autoload -Uz compinit
    compinit
    save_source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh
fi
