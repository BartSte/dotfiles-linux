dir=~/dotfiles-linux/dependencies

install_python_packages () {
    echo "Install python packages"
    pip install pipx
    xargs -n 1 pipx install < $1
}

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

# See BarsSte/tmux-session
install-tmux-session () {
    echo "Install tmux-session"
    local tmp_dir=$(mktemp -d);
    git clone https://github.com/BartSte/tmux-session.git $tmp_dir;
    sudo $tmp_dir/install;
    rm -rf $tmp_dir;
}

# See BarsSte/fzf-help
install_fzf_help(){
    bash -c 'tmp_dir=$(mktemp -d); git clone https://github.com/BartSte/fzf-help.git $tmp_dir; $tmp_dir/install; rm -rf $tmp_dir;'
}

