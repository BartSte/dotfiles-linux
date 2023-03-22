enable_service() {
    sudo killall kmonad
    sudo systemctl disable kmonad.service

    pushd .
    cd ~/dotfiles-linux/kmonad
    sudo cp kmonad.service /etc/systemd/system
    sudo cp home_row_modifiers.kbd /etc/systemd/system

    cd /etc/systemd/system
    sudo chmod 644 kmonad.service
    sudo chmod 644 home_row_modifiers.kbd
    sudo chown root kmonad.service
    sudo chown root home_row_modifiers.kbd

    popd
    sudo systemctl start kmonad.service
    sudo systemctl enable kmonad.service
}

if ! running_wsl; then
    enable_service
fi
