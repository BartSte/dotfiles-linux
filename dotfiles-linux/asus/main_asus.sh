#!/bin/bash

# The following function are specifically for the asus vivobook 

function copy_backlight_config() {
    sudo cp ~/dotfiles-linux/asus/20-intel.conf /etc/X11/xorg.conf.d/20-intel.conf --no-clobber
}

function copy_wireless_adapter_config() {
    sudo cp ~/dotfiles-linux/asus/main.conf /etc/iwd/main.conf
}

copy_backlight_config
copy_wireless_adapter_config
sudo pacman -S xf86-video-intel intel-gpu-tools mesa mkinitcpio-firmware
