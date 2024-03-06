link_config() {
    target=~/dotfiles/qutebrowser/config.py
    link=~/.config/qutebrowser/config.py

    echo "Create link from $target to $link"
    mkdir -p $(dirname $link)
    ln -sf $target $link
}

link_bookmarks() {
    target_urls="$HOME/dotfiles/qutebrowser/urls"
    target_quickmarks="$HOME/dotfiles/qutebrowser/quickmarks"

    link_urls="$HOME/.config/qutebrowser/bookmarks/urls"
    link_quickmarks="$HOME/.config/qutebrowser/quickmarks"

    echo "Create links from $target_urls to $link_urls"
    echo "Create links from $target_quickmarks to $link_quickmarks"
    mkdir -p $(dirname $link_urls)
    mkdir -p $(dirname $link_quickmarks)
    ln -sf $target_urls $link_urls
    ln -sf $target_quickmarks $link_quickmarks
}
