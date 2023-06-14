[ -f ~/.zshenv ] && source ~/.zshenv
[ -f ~/.zshrc ] && source ~/.zshrc

if ! running_wsl && [[ -z $DISPLAY ]]; then 
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway
    elif [[ $(tty) = /dev/tty2 ]]; then
        exec startx
    fi
fi
