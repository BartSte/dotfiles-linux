install_python_packages() {
    echo "Install python packages"
    local deps_file="$1"
    xargs -n 1 pipx install <"$deps_file"
}

install_node_js() {
    echo "Install node.js"
    sudo bash -c "$(curl -sL install-node.vercel.app/lts)" -y -f
}

install_yay() {
    local dir="$1"
    git clone https://aur.archlinux.org/yay.git "$dir"
    old_dir=$(pwd)
    cd "$dir" || exit
    export PACMAN_NO_CONFIRM=1  # Disable interactive confirmations
    makepkg -s --noconfirm  # Pipe yes to any remaining prompts
    sudo pacman -U --noconfirm *.pkg.tar.*
    cd "$old_dir" || exit
    rm -rf "$dir"
}
