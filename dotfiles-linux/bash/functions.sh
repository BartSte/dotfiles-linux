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
