if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

if [[ -z $DISPLAY ]] && ! [[ -e /tmp/.X11-unix/X0 ]] && (( EUID )); then
      exec startx
fi


