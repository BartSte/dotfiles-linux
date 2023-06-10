if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

if [[ $(tty) = /dev/tty1 ]]; then
    exec sway
elif [[ $(tty) = /dev/tty2 ]]; then
    exec startx
fi
