function install_vim_plug () {
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

function install_node_js () {
    curl -sL install-node.vercel.app/lts | bash
}

function upgrade_vim () {
    sudo add-apt-repository ppa:jonathonf/vim
    sudo apt update
    sudo apt install vim
}

function install_dependencies () {
    for dep in $1
    do
        sudo apt install $dep
    done
}
