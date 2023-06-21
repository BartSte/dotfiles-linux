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

link_scripts_to_bin() {
    echo "Link scripts to the ~/bin folder"
    ln ~/dotfiles/scripts/sorters/sort_variable_length.py ~/bin/sort_variable_length
}

initialize_tulizu() {
    sudo tulizu install ~/dotfiles-linux/dependencies/arch-linux-logo.issue
}

