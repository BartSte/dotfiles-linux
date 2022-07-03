function install_font () {
    unzip -u ~/dotfiles/fonts/JetBrainsMono.zip -d ~/.fonts
    fc-cache -fv
}

install_font
