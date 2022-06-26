#!/bin/bash
function init_git() {
    git config --global credential.helper store
}

function add_ppa_python () {
    sudo add-apt-repository ppa:deadsnake/ppa
}

function download_mutt_oauth2() {
 wget -O ~/.mutt/scripts/mutt_oauth2.py https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py
 cd ~/.mutt/scripts
 chmod +x mutt_oauth2.py
}

function add_ppa_alacritty () {
    sudo add-apt-repository ppa:aslatter/ppa
}

function install_dependencies () {
    sudo apt install "$@"
}

function install_font () {
    unzip -u ~/dotfiles/fonts/JetBrainsMono.zip -d ~/.fonts
    fc-cache -fv
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

function install_polybar_collections() {
    git clone https://github.com/BartSte/polybar-collection ~/polybar-collection
    git switch develop
    git pull
    cp ~/polybar-collection/fonts ~/.fonts
    cd ~/.fonts
    fc-cache -fv
    ~
}

function copy_win_firefox_to_binaries() {
    sudo cp ~/dotfiles-linux/firefox_win /usr/bin/firefox --no-clobber
}

function running_wsl() {
    if grep -q microsoft /proc/version; then
        true
    else
        false
    fi
}

function set_time_zone() {
    sudo timedatectl set-timezone $1
}
