install_node_js () {
    echo "Install node.js"
    sudo bash -c "$(curl -sL install-node.vercel.app/lts)" -y -f
}

install_yay () {
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
    ~
}

install_dependencies () {
    echo "Install pacman dependencies"
    sudo pacman -S "$@" --noconfirm
}
 
install_dependencies_aur () {
    echo "Install yay dependencies"
    yay -S "$@" --noconfirm
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

