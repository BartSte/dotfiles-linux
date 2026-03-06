fpath=(~/dotfiles-linux/zsh/completions $fpath)

if [[ -f ~/.openclaw/completions/openclaw.zsh ]]; then
    fpath=(~/.openclaw/completions $fpath)
fi

if [[ -f /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh ]]; then
    autoload -Uz compinit
    compinit
    save-source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh
fi
