[[ -f ~/.zshenv ]] && . "$HOME"/.zshenv
[[ -f ~/.zshrc ]] && . "$HOME"/.zshrc

if ! running wsl && ! running raspberry; then
    if [[ $(tty) = /dev/tty1 ]]; then
        export XDG_CURRENT_DESKTOP=sway
        exec sway -c ~/dotfiles-linux/sway/wayland
    elif [[ $(tty) = /dev/tty2 ]]; then
        export XDG_CURRENT_DESKTOP=sway
        exec sway -c ~/dotfiles-linux/sway/xwayland
    fi
fi
