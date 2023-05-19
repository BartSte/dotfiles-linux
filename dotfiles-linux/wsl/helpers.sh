enable_systemd() {
    echo "Enable systemd for WSL"
    sudo cp ~/dotfiles-linux/wsl/wsl.conf /etc/wsl.conf
}
