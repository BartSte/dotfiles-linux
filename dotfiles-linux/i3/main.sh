. ~/dotfiles-linux/dependencies/deps.sh
. ~/dotfiles-linux/dependencies/helpers.sh

function install_polybar_collections() {
    echo "Clone BartSte/polybar-collection"
    git clone https://github.com/BartSte/polybar-collection ~/polybar-collection
    git switch develop
    git pull
    cp ~/polybar-collection/fonts ~/.fonts -r
    cd ~/.fonts
    fc-cache -fv
    cd ~
}

function set_time_zone() {
    echo "Set timezone to $1"
    sudo timedatectl set-timezone $1
}

running_wsl && return

echo "# I3 window manager"
install_polybar_collections 
set_time_zone $TIME_ZONE
install_dependencies "${dependencies_extra[@]}"
systemctl start bluetooth
