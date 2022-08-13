function install_node_js () {
    echo "Install node.js"
    sudo bash -c "$(curl -sL install-node.vercel.app/lts)" -y -f
}

function install_yay () {
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
    ~
}

function install_chrysalis() {
    echo "Install Chrysalis"
    pushd
    cd /tmp
    # TODO write a function that uses curl to determine the latest release
    # For example: https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
    # Make appimage executable
    # Move it to /usr/bin/ or ~/.local/bin
    popd
}

function install_dependencies () {
    echo "Install pacman dependencies"
    sudo pacman -S "$@" --noconfirm
}
 
function install_dependencies_aur () {
    echo "Install pacman dependencies"
    sudo yay -Ss "$@" --noconfirm
}
