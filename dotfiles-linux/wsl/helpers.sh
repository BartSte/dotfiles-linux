function running_wsl() {
    if grep -q microsoft /proc/version; then
        true
    else
        false
    fi
}

function copy_win_firefox_to_binaries() {
    sudo cp ~/dotfiles-linux/firefox_win /usr/bin/firefox --no-clobber
    sudo chmod +x /usr/bin/firefox
}

