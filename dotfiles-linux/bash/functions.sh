save_source() {
    [ -f "$1" ] && source "$1"
}

del(){
    rmtrash $@
}

