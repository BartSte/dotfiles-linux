. ~/dotfiles-linux/dependencies/deps.sh
. ~/dotfiles-linux/dependencies/helpers.sh

function init_polybar() {
    cp ~/dotfiles-linux/i3/polybar-collection/fonts ~/.fonts -r
    pushd .
    cd ~/.fonts
    fc-cache -fv
    popd
}

function set_time_zone() {
    echo "Set timezone to $1"
    sudo timedatectl set-timezone $1
}

function init_bluetooth() {
    sudo systemctl start bluetooth
    sudo systemctl enable bluetooth
    bluetoothctl power on
    bluetoothctl discoverable on
    bluetoothctl pairable on
}

set_shadowfox() {
    shadowfox-updater -profile-index 0
    shadowfox-updater -set-dark-theme 1
}

running_wsl && return

echo "# I3 window manager"
init_polybar 
set_time_zone $TIME_ZONE
install_dependencies "${dependencies_extra[@]}"
install_chrysalis
init_bluetooth
set_shadowfox
install_tridactyl_native
