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
    echo "Install yay dependencies"
    sudo yay -S "$@" --noconfirm
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

link_scripts_to_bin() {
    echo "Link scripts to the ~/bin folder"
    ln ~/dotfiles/scripts/sorters/sort_variable_length.py ~/bin/sort_variable_length
}

install_tridactyl_native() {
    curl -fsSl https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/install.sh -o /tmp/trinativeinstall.sh && sh /tmp/trinativeinstall.sh 1.22.1
}

initialize_tulizu() {
    sudo tulizu install ~/dotfiles-linux/dependencies/arch-linux-logo.issue
}

link_qutebrowser_config() {
    echo "Link qutebrowser config"
    source=~/dotfiles/qutebrowser/config.py
    destination=~/.config/qutebrowser/config.py
    rm $destination
    ln $source $destination
}

