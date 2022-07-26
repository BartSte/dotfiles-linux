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

function install_dependencies () {
    echo "Install pacman dependencies"
    sudo pacman -S "$@" --noconfirm
}
 
function install_dependencies_aur () {
    echo "Install pacman dependencies"
    sudo yay -Ss "$@" --noconfirm
}
