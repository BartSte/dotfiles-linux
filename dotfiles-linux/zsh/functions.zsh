source /usr/share/fzf/key-bindings.zsh

save_source() {
    [ -f "$1" ] && source "$1"
}

del(){
    rmtrash $@
}

fps() {
    ps aux | fzf
}

fkill() {
  local pid

  pid="$(
    ps -ef \
      | sed 1d \
      | fzf -m \
      | awk '{print $2}'
  )" || return

  kill -"${1:-9}" "$pid"
}

act() {
    source .venv/bin/activate > /dev/null 2>&1
}

vims() {
    [ -f Session.vim ] && {act;nvim -S Session.vim $@} || echo "No session found."
}

fzf-file-widget-home() {
    _OLD_FZF_CTRL_T_COMMAND=$FZF_CTRL_T_COMMAND
    _OLD_FZF_CTRL_T_OPTS=$FZF_CTRL_T_OPTS

    FZF_CTRL_T_COMMAND=$FZF_ALT_H_COMMAND
    FZF_CTRL_T_OPTS=$FZF_ALT_H_OPTS

    fzf-file-widget

    FZF_CTRL_T_COMMAND=$_OLD_FZF_CTRL_T_COMMAND
    FZF_CTRL_T_OPTS=$_OLD_FZF_CTRL_T_OPTS
}

fzf-cd-widget-home() {
    _OLD_FZF_ALT_C_COMMAND=$FZF_ALT_C_COMMAND
    _OLD_FZF_ALT_C_OPTS=$FZF_ALT_C_OPTS

    FZF_ALT_C_COMMAND=$FZF_ALT_D_COMMAND
    FZF_ALT_C_OPTS=$FZF_ALT_D_OPTS

    fzf-cd-widget

    FZF_ALT_C_COMMAND=$_OLD_FZF_ALT_C_COMMAND
    FZF_ALT_C_OPTS=$_OLD_FZF_ALT_C_OPTS
}

fzfrbw-widget() {
    fzfrbw
    zle reset-prompt
}

man-widget() {
    [[ -z $BUFFER ]] || eval "man $BUFFER"
    zle reset-prompt
}

