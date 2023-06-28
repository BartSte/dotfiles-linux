#!/bin/bash

echo "Installing BartSte/dotfiles-linux repository"
#TODO -> automate creating the .dotfiles_config file
~/dotfiles-linux/bitwarden/main.sh
~/dotfiles-linux/git/main.sh
~/dotfiles-linux/dependencies/main.sh
~/dotfiles-linux/wsl/main.sh
~/dotfiles-linux/nvim/main.sh
~/dotfiles-linux/gpg/main.sh
~/dotfiles-linux/mutt/main.sh
~/dotfiles-linux/kmonad/main.sh
~/dotfiles-linux/davmail/main.bash
~/dotfiles-linux/zsh/main
~/dotfiles-linux/tmux/main

echo "Done"
