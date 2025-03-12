install_node_js() {
    echo "Install node.js"
    sudo bash -c "$(curl -sL install-node.vercel.app/lts)" -y -f
}

install_yay() {
    local dir="$1"
    git clone https://aur.archlinux.org/yay.git "$dir"
    old_dir=$(pwd)
    cd "$dir" || exit
    makepkg -s --noconfirm
    sudo pacman -U --noconfirm *.pkg.tar.*
    cd "$old_dir" || exit
    rm -rf "$dir"
}
