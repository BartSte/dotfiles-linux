export PATH=$PATH:$HOME/bin:$HOME/.local/bin:$HOME/.emacs.d/bin

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

if ! grep -q microsoft /proc/version && [ -z "${DISPLAY}" ]; then 
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway
    elif [[ $(tty) = /dev/tty2 ]]; then
        exec startx
    fi
fi
