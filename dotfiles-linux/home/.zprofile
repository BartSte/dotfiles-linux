if [[ -z ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} ]] &&
    ! [[ -r /proc/device-tree/model && "$(</proc/device-tree/model)" == *"Raspberry Pi"* ]]; then
    if [[ $TTY = /dev/tty1 ]]; then
        exec sway -c ~/dotfiles-arch/sway/wayland
    elif [[ $TTY = /dev/tty2 ]]; then
        exec sway -c ~/dotfiles-arch/sway/xwayland
    fi
fi
