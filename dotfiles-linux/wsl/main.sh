#!/bin/bash

. ~/dotfiles-linux/wsl/helpers.sh

echo "# WSL"
running_wsl && enable_firefox_win
running_wsl && enable_systemd 
