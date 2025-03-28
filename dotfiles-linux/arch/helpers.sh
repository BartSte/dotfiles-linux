install_node_js() {
    echo "Install node.js"
    sudo bash -c "$(curl -sL install-node.vercel.app/lts)" -y -f
}

install_yay() {
    local dir="$1"
    git clone https://aur.archlinux.org/yay.git "$dir"
    old_dir=$(pwd)
    cd "$dir" || exit
    makepkg -si --noconfirm
    cd "$old_dir" || exit
    rm -rf "$dir"
}

update_mirrors() {
    echo "Update mirrors"
    sudo reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
}
