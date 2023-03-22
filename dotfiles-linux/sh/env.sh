export EDITOR='nvim'
export GPG_TTY=$(tty)
export HEADPHONES='28:11:A5:A4:3A:CF'

export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore-vcs --ignore-file $HOME/.ignore --type f"
export FZF_ALT_C_COMMAND="fd --hidden --no-ignore-vcs --ignore-file $HOME/.ignore -t d"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_H_COMMAND="$FZF_DEFAULT_COMMAND . $HOME"
export FZF_ALT_D_COMMAND="$FZF_ALT_C_COMMAND . $HOME"

export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --preview-window=right,65%"

_FZF_CTRL_T_OPTS_FILES='bat --theme=gruvbox-dark --style=numbers --color=always --line-range :500 {}'
_FZF_CTRL_T_OPTS_DIR='exa --icons -T -L 1 -a {} | head -200'
_FZF_CTRL_T_OPTS_BIND="ctrl-d:reload($FZF_ALT_C_COMMAND)+change-preview($_FZF_CTRL_T_OPTS_DIR)+change-preview-window(hidden),"
_FZF_CTRL_T_OPTS_BIND+="ctrl-o:reload($FZF_CTRL_T_COMMAND)+change-preview($_FZF_CTRL_T_OPTS_FILES)+change-preview-window(hidden),"
_FZF_CTRL_T_OPTS_BIND+="ctrl-p:toggle-preview"
FZF_CTRL_T_OPTS="--bind '$_FZF_CTRL_T_OPTS_BIND' "
FZF_CTRL_T_OPTS+="--preview '$_FZF_CTRL_T_OPTS_FILES' "
FZF_CTRL_T_OPTS+="--preview-window 'hidden'"
export FZF_CTRL_T_OPTS

_FZF_ALT_H_OPTS_BIND="ctrl-d:reload($FZF_ALT_C_COMMAND . $HOME)+change-preview($_FZF_CTRL_T_OPTS_DIR)+change-preview-window(hidden),"
_FZF_ALT_H_OPTS_BIND+="ctrl-o:reload($FZF_CTRL_T_COMMAND . $HOME)+change-preview($_FZF_CTRL_T_OPTS_FILES)+change-preview-window(hidden),"
_FZF_ALT_H_OPTS_BIND+="ctrl-p:toggle-preview"
FZF_ALT_H_OPTS="--bind '$_FZF_ALT_H_OPTS_BIND' "
FZF_ALT_H_OPTS+="--preview '$_FZF_CTRL_T_OPTS_FILES' "
FZF_ALT_H_OPTS+="--preview-window 'hidden'"
export FZF_ALT_H_OPTS

FZF_ALT_C_OPTS="--preview '$_FZF_CTRL_T_OPTS_DIR' "
FZF_ALT_C_OPTS+="--bind 'ctrl-p:toggle-preview' "
FZF_ALT_C_OPTS+="--preview-window hidden"
export FZF_ALT_C_OPTS

export FZF_ALT_D_OPTS=$FZF_ALT_C_OPTS

export FZF_COMPLETION_OPTS='--info=inline'
