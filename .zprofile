[ -f ~/.zshenv ] && source ~/.zshenv
[ -f ~/.zshrc ] && source ~/.zshrc

if ! running_wsl && [[ -z $DISPLAY ]]; then 
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway
    elif [[ $(tty) = /dev/tty2 ]]; then
        #TODO: remove X11 and activate xwayland for sway instead on tty2
        exec startx
    fi
fi
