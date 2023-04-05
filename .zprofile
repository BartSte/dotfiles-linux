export PATH=$PATH:$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin

if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

if ! running_wsl && [ -z "${DISPLAY}" ]; then 
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway
    elif [[ $(tty) = /dev/tty2 ]]; then
        exec startx
    fi
else
    wsl_path=/mnt/c/Windows/System32:
    wsl_path+=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:
    wsl_path+=/mnt/c/Program\ Files/PowerShell/7-preview

    export PATH=$PATH:$wsl_path
fi

