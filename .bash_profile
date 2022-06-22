if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi
if ! grep -q microsoft /proc/version && [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
      exec startx
fi
