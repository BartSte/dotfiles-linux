function add_ppa_python () {
    echo "Add ppa python"
    sudo add-apt-repository ppa:deadsnake/ppa -y
}

function add_ppa_alacritty () {
    echo "Add ppa alacritty"
    sudo add-apt-repository ppa:aslatter/ppa -y
}

function install_node_js () {
    echo "Install node.jf"
    sudo bash -c "$(curl -sL install-node.vercel.app/lts)" -y -f
}

function install_dependencies () {
    echo "Install apt dependencies"
    sudo apt install "$@" -y
}
