. ~/dotfiles-linux/config.sh
. ~/dotfiles-linux/dependencies/helpers.sh

function install_polybar_collections() {
    git clone https://github.com/BartSte/polybar-collection ~/polybar-collection
    git switch develop
    git pull
    cp ~/polybar-collection/fonts ~/.fonts
    cd ~/.fonts
    fc-cache -fv
    cd ~
}

function set_time_zone() {
    sudo timedatectl set-timezone $1
}

install_polybar_collections 
set_time_zone $TIME_ZONE
install_dependencies "$dependencies_snap[@]"
install_dependencies "$dependencies_extra[@]"
