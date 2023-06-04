
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


