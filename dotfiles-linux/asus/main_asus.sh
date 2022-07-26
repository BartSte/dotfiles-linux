#!/bin/bash

# The following function are specifically for the asus vivobook running ubuntu 22

function copy_backlight_config() {
    sudo cp ~/dotfiles-linux/asus/20-intel.conf /etc/X11/xorg.conf.d/20-intel.conf --no-clobber
}

copy_backlight_config
