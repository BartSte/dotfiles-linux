function add_ppa_python () {
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:deadsnake/ppa
}

function download_mutt_oauth2() {
 wget -O ~/.mutt/scripts/mutt_oauth2.py https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py
 cd ~/.mutt/scripts
 chmod +x mutt_oauth2.py
}

function add_ppa_vim () {
    sudo add-apt-repository ppa:jonathonf/vim
}

function install_dependencies () {
    deps=$1
    for dep in "${deps[@]}" 
    do
        sudo apt install $dep
    done
}

function install_font () {
    wget https://download.jetbrains.com/fonts/JetBrainsMono-1.0.0.zip
    unzip JetBrainsMono-1.0.0.zip
}

function install_node_js () {
    curl -sL install-node.vercel.app/lts | sudo bash
}

function install_vim_plug () {
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim -c PlugInstall\|qa!
}

function build_fzf () {
    ~/.vim/plugged/fzf/install --all
}

