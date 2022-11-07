PATH+=":$HOME/bin"
PATH+=":$HOME/.local/bin"

if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

if ! grep -q microsoft /proc/version && [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
     exec startx
fi

if ! grep -q microsoft /proc/version && [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 2 ]; then
     exec sway
fi
