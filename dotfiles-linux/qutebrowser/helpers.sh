link_config() {
    target=~/dotfiles/qutebrowser/config.py
    link=~/.config/qutebrowser/config.py
    ln -sf $target $link
}

# The bookmarks are private and shared across Dropbox.
link_bookmarks() {
    if running_wsl; then
        target="/mnt/c/Users/$(whoami)/Dropbox/config/urls"
    else
        target=~/Dropbox/config/urls
    fi
    link=~/.config/qutebrowser/bookmarks/urls
    ln -sf $target $link
}
