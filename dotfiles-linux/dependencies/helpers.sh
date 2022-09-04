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

function install_chrysalis() {
    echo "Install Chrysalis"

    releases='https://github.com/keyboardio/Chrysalis/releases/'
    name=$(curl "$releases" -s|ag -o download.*\.AppImage|head -1)

    echo $releases$name 
    pushd .
    cd /tmp
    mkdir chrysalis
    cd chrysalis
    wget $releases$name --quiet
    sudo rm /usr/bin/chrysalis
    sudo mv *.AppImage /usr/bin/chrysalis
    chmod +x /usr/bin/chrysalis
    rmdir /tmp/chrysalis
    popd
}

install_bash_tab_completion() {
    pushd .
    cd ~/clones
    git clone https://github.com/lincheney/fzf-tab-completion
    popd
}

