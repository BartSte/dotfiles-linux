save_source() {
    [ -f "$1" ] && source "$1"
}

del(){
    rmtrash $@
}

mymailsync() {
    mailsync $HOME/.config/davmail/davmail.properties
}

mycalsync() {
    calsync \
        $HOME/.config/davmail/davmail.properties \
        $HOME/Dropbox/org/outlook.org \
        outlook_local today 180d 
}

append_line() {
    if [[ -p /dev/stdin ]]; then
        READLINE_LINE_NEW=$(cat -)
    else
        READLINE_LINE_NEW=$@
    fi

    if
        [[ -n $READLINE_LINE_NEW ]]
    then
        builtin bind '"\er": redraw-current-line'
        builtin bind '"\e^": magic-space'
        READLINE_LINE_NEW+=" "
        READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${READLINE_LINE_NEW}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
        READLINE_POINT=$(( READLINE_POINT + ${#READLINE_LINE_NEW} ))
    else
        builtin bind '"\er":'
        builtin bind '"\e^":'
    fi
}
