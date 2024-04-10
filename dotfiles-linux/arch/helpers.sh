install_python_packages() {
    echo "Install python packages"
    local deps_file="$1"
    pip install pipx
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
    makepkg -si --noconfirm
    rm -rf "$dir"
    cd "$old_dir" || exit
}

# See BarsSte/tmux-session
install-tmux-session() {
    echo "Install tmux-session"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone https://github.com/BartSte/tmux-session.git "$tmp_dir"
    sudo "$tmp_dir"/install
    rm -rf "$tmp_dir"
}
