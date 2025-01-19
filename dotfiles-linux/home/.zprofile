[[ -f ~/.zshenv ]] && . "$HOME"/.zshenv
[[ -f ~/.zshrc ]] && . "$HOME"/.zshrc

if ! is_running wsl && ! is_running raspberry; then
    if [[ $(tty) = /dev/tty1 ]]; then
        exec sway -c ~/dotfiles-linux/sway/wayland
    elif [[ $(tty) = /dev/tty2 ]]; then
        exec sway -c ~/dotfiles-linux/sway/xwayland
    fi
fi
