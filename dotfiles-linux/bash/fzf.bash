source ~/dotfiles-linux/scripts/fzf_help.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash

export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore --type f"
export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --preview-window=right,60%"

export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
command -v exa > /dev/null && export FZF_CTRL_T_OPTS="--bind 'ctrl-d:reload($FZF_ALT_C_COMMAND),ctrl-f:reload($FZF_DEFAULT_COMMAND)' --preview 'bat --theme=gruvbox-dark --style=numbers --color=always --line-range :500 {} || exa --icons -T -a {} | head -200'"

export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore -t d"
command -v exa > /dev/null && export FZF_ALT_C_OPTS='--preview "exa --icons -T -a {} | head -200"'

export FZF_COMPLETION_TRIGGER=""
export FZF_COMPLETION_OPTS='--info=inline'

_fzf_compgen_path() {
  fd --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

