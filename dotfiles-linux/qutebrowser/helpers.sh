link_config() {
    target=~/dotfiles/qutebrowser/config.py
    link=~/.config/qutebrowser/config.py
    ln -sf $target $link
}

# The bookmarks are private and shared across Dropbox.
link_bookmarks() {
    if running_wsl; then
        target="$WH/Dropbox/Config/urls"
    else
        target=~/Dropbox/Config/urls
    fi
    link=~/.config/qutebrowser/bookmarks/urls
    ln -sf $target $link
}
