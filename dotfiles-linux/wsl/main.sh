#!/bin/bash

. ~/dotfiles-linux/wsl/helpers.sh

echo "Configure WSL if running on WSL"
running_wsl && enable_systemd 
