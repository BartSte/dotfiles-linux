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
    running_wsl && dropbox=$WH/Dropbox || dropbox=$HOME/Dropbox
    calsync \
        $HOME/.config/davmail/davmail.properties \
        $dropbox/org/outlook.org \
        outlook_local today 180d 
}
