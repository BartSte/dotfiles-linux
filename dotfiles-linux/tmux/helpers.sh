install_tmux_plugin() {
    echo "Installing tmux fzf url"

    [[ -z $TMUX_PLUGIN_DIR ]] || {echo "TMUX_PLUGIN_DIR is not set" && exit 1}

    local url=$1
    local name=$(echo $url | awk -F/ '{print $NF}' | sed -e 's/\.git$//')
    local path="$TMUX_PLUGIN_DIR/$name"

    echo "Installing $name"

    mkdir -p $TMUX_PLUGIN_DIR
    git clone $url $path
}

install_tmux_session() {
    echo "Installing tmux-session"

    local tmp_dir=$(mktemp -d)

    git clone https://github.com/BartSte/tmux-session.git $tmp_dir
    sudo $tmp_dir/install
    rm -rf $tmp_dir
}

link_tmux_session() {
    echo "Linking tmux-session config"

    path=~/dotfiles-linux/tmux/tmux-session/
    target=~/.config

    echo "Symbolic link from $path to $target"
    ln -sf $path $target
}
