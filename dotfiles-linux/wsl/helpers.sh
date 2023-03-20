enable_firefox_win() {
    echo "Use windows's firefox for linux"
    rm $HOME/bin/firefox
    sudo ln --symbolic $HOME/dotfiles-linux/wsl/firefox_win $HOME/bin/firefox
}

enable_systemd() {
    echo "Enable systemd for WSL"
    sudo cp ~/dotfiles-linux/wsl/wsl.conf /etc/wsl.conf
}
