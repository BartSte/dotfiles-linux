link_config() {
    target=~/dotfiles/qutebrowser/config.py
    link=~/.config/qutebrowser/config.py

    echo "Create link from $target to $link"
    ln -sf $target $link
}

# The bookmarks are private and shared across Dropbox.
link_bookmarks() {
    if running_wsl; then
        target_urls="$WH/Dropbox/Config/urls"
        target_quickmarks="$WH/Dropbox/Config/quickmarks"
    else
        target_urls="$HOME/Dropbox/Config/urls"
        target_quickmarks="$HOME/Dropbox/Config/quickmarks"
    fi

    link_urls="$HOME/.config/qutebrowser/bookmarks/urls"
    link_quickmarks="$HOME/.config/qutebrowser/quickmarks"

    echo "Create links from $target_urls to $link_urls"
    echo "Create links from $target_quickmarks to $link_quickmarks"
    ln -sf $target_urls $link_urls
    ln -sf $target_quickmarks $link_quickmarks
}
