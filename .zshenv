wayland_env(){
    export QT_QPA_PLATFORMTHEME=qt5ct
    export QT_QPA_PLATFORM=wayland
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_DESKTOP=sway
}

wsl_env(){
    wsl_path=/mnt/c/Windows/System32:
    wsl_path+=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:
    wsl_path+=/mnt/c/Program\ Files/PowerShell/7-preview/:
    wsl_path+=/mnt/c/Python310/
    export PATH=$PATH:$wsl_path
}

general_env() {
    typeset -U PATH path  # remove duplicat entries from $PATH
    export PATH=$PATH:$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin
    source ~/dotfiles-linux/sh/env.sh
}

general_env

if ! running_wsl && [[ -z $DISPLAY ]]; then
    if [[ $(tty) = /dev/tty1 ]]; then
        wayland_env
    fi
    # No environment variables need to be set for X11
else
    wsl_env
fi
