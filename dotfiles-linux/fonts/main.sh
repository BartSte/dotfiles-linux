#!/bin/bash

function install_font () {
    echo "Install JetBrainsMono Nerd Font"
    unzip -u ~/dotfiles/fonts/JetBrainsMono.zip -d ~/.fonts
    fc-cache -fv
}

echo "# Fonts"
install_font
