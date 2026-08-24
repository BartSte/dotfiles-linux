fpath=(~/dotfiles-linux/zsh/completions $fpath)

if [[ -f ~/.openclaw/completions/openclaw.zsh ]]; then
    fpath=(~/.openclaw/completions $fpath)
fi

autoload -Uz compinit
typeset -g ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

if [[ -s $ZSH_COMPDUMP && -z $ZSH_COMPDUMP(#qN.mh+24) ]]; then
    compinit -C -d "$ZSH_COMPDUMP"
else
    compinit -d "$ZSH_COMPDUMP"
fi

if [[ -f /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh ]]; then
    save-source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh
fi
