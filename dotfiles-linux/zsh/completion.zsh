fpath=(~/dotfiles-linux/zsh/completions $fpath)

if [[ -f /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh ]]; then
    autoload -Uz compinit
    compinit
    save-source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh
fi
