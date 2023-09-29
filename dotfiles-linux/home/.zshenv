[ $OLD_PATH ] || export OLD_PATH=$PATH

export PATH=$OLD_PATH:$HOME/dotfiles-linux/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin
export BROWSER='qutebrowser'
export WSLBROWSER='/mnt/c/Program Files/qutebrowser/qutebrowser.exe'
export EDITOR='nvim'
export GPG_TTY=$(tty)
export EARBUDS='30:53:C1:B8:CE:F6'
export ESCDELAY=0
export MANPAGER="nvim +Man!"
export TIME_ZONE="Europe/Amsterdam"
export HEADPHONES='28:11:A5:A4:3A:CF'
export PYTHONBREAKPOINT='ipdb.set_trace'
export IPDB_CONTEXT_SIZE=10
export TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
export TVIM_WINDOW="0"
export TVIM_PANE="0"
export VI_MODE_SET_CURSOR=true
export FZF_HELP_SYNTAX='help'
# export CLI_OPTIONS_CMD='ag -o --numbers -- $RE'

export HISTFILE=~/.histfile
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000

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