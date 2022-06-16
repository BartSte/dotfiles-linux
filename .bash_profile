if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

if ! grep -q microsoft /proc/version; then
    if [[ -z $DISPLAY ]] && ! [[ -e /tmp/.X11-unix/X0 ]] && (( EUID )); then
          exec startx
    fi
fi

