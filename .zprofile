[ -f ~/.zshenv ] && source ~/.zshenv
[ -f ~/.zshrc ] && source ~/.zshrc

if ! running_wsl; then 
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway -c ~/dotfiles-linux/sway/wayland
    elif [[ $(tty) = /dev/tty2 ]]; then
        exec sway -c ~/dotfiles-linux/sway/xwayland
    fi
fi
