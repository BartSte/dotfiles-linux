[[ -f ~/.zshenv ]] && . "$HOME"/.zshenv
[[ -f ~/.zshrc ]] && . "$HOME"/.zshrc

if ! running_wsl && ! running_raspberry; then
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway -c ~/dotfiles-linux/sway/wayland
    elif [[ $(tty) = /dev/tty2 ]]; then
        exec sway -c ~/dotfiles-linux/sway/xwayland
    fi
fi
