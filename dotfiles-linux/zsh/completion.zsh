save_source() {
    local file=$1
    if [ -f "$file" ]; then
        source $file
    fi
}

zstyle :compinstall filename '~/.zshrc'
autoload -Uz compinit
compinit
save_source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh
