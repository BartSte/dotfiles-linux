source ~/dotfiles-linux/scripts/fzf_help.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash

export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore --type f"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --preview-window=right,65%"

_FZF_CTRL_T_OPTS_FILES='bat --theme=gruvbox-dark --style=numbers --color=always --line-range :500 {}'
_FZF_CTRL_T_OPTS_DIR='exa --icons -T -L 1 -a {} | head -200'
_FZF_CTRL_T_OPTS_BIND="ctrl-d:reload($FZF_ALT_C_COMMAND)+change-preview($_FZF_CTRL_T_OPTS_DIR)+toggle-preview,"
_FZF_CTRL_T_OPTS_BIND+="ctrl-f:reload($FZF_CTRL_T_COMMAND)+change-preview($_FZF_CTRL_T_OPTS_FILES)+change-preview-window(hidden),"
_FZF_CTRL_T_OPTS_BIND+="ctrl-s:toggle-preview"
export FZF_CTRL_T_OPTS="--bind '$_FZF_CTRL_T_OPTS_BIND' "
export FZF_CTRL_T_OPTS+="--preview '$_FZF_CTRL_T_OPTS_FILES' "
export FZF_CTRL_T_OPTS+="--preview-window 'hidden'"

export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --max-depth 4 --ignore-file $HOME/.ignore -t d"
export FZF_ALT_C_OPTS="--preview '$_FZF_CTRL_T_OPTS_DIR' "
export FZF_ALT_C_OPTS+="--bind 'ctrl-s:toggle-preview' "
export FZF_ALT_C_OPTS+="--preview-window hidden"

export FZF_COMPLETION_TRIGGER="**"
export FZF_COMPLETION_OPTS='--info=inline'

_fzf_compgen_path() {
  fd --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --max-depth 4 --ignore-file $HOME/.ignore . "$1"
}

