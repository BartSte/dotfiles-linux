function add_ppa_python () {
    sudo add-apt-repository ppa:deadsnake/ppa
}

function add_ppa_alacritty () {
    sudo add-apt-repository ppa:aslatter/ppa
}

function install_node_js () {
    curl -sL install-node.vercel.app/lts | sudo bash
}

function install_dependencies () {
    sudo apt install "$@"
}
