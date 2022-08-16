source ~/dotfiles-linux/scripts/fzf_help.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash

export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore"
export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border"

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS='--preview "bat --theme=gruvbox-dark --style=numbers --color=always --line-range :500 {}"'

export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore -t d"
command -v exa > /dev/null && export FZF_ALT_C_OPTS='--preview "exa --icons -T -a {} | head -200"'

export FZF_COMPLETION_TRIGGER=""
export FZF_COMPLETION_OPTS='--border --info=inline'

_fzf_compgen_path() {
  fd --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

