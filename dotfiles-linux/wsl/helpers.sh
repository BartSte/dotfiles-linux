function enable_running_wsl () {
    echo "Enable running_wsl"
    sudo cp ~/dotfiles-linux/wsl/running_wsl /usr/bin/running_wsl
    sudo chmod u+x /usr/bin/running_wsl
}

function copy_win_firefox_to_binaries() {
    echo "Use windows's firefox for linux"
    sudo cp ~/dotfiles-linux/wsl/firefox_win /usr/bin/firefox
    sudo chmod +x /usr/bin/firefox
}

