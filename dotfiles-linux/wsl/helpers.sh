function running_wsl() {
    if grep -q microsoft /proc/version; then
        echo "WSL is active"
        true
    else
        echo "WSL is not active"
        false
    fi
}

function copy_win_firefox_to_binaries() {
    echo "Use windows's firefox for linux"
    sudo cp ~/dotfiles-linux/wsl/firefox_win /usr/bin/firefox --no-clobber
    sudo chmod +x /usr/bin/firefox
}

