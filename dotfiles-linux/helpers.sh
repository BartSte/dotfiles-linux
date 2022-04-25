function install_python () {
    sudo apt update 
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:deadsnake/ppa
    suod apt install python3.8
}
function install_font () {
    wget https://download.jetbrains.com/fonts/JetBrainsMono-1.0.0.zip
    unzip JetBrainsMono-1.0.0.zip
}

function install_vim_plug () {
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

function install_node_js () {
    curl -sL install-node.vercel.app/lts | sudo bash
}

function upgrade_vim () {
    sudo add-apt-repository ppa:jonathonf/vim
    sudo apt update
    sudo apt install vim
}

function vim_plug_install () {
    vim -c PlugInstall\|qa!
}

function build_fzf () {
    ~/.vim/plugged/fzf/install --all
}

function install_dependencies () {
    deps=$1
    for dep in ${deps[@]}; do
        sudo apt install $dep
    done
}
