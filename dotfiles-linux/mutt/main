#!/bin/bash

echo "# Neomutt"
repo_gruvbox=https://git.sthu.org/repos/mutt-gruvbox.git 
repo_powerline=https://github.com/sheoak/neomutt-powerline-nerdfonts.git
directory="$HOME/.config/neomutt"
cache="$HOME/.cache/neomutt"

mkdir $directory
rm $directory/muttrc
ln --symbolic $HOME/dotfiles-linux/mutt/muttrc $directory/muttrc

mkdir -p $HOME/.local/share/mail/INBOX
mkdir -p $cache
touch $cache/header_cache

git clone $repo_gruvbox $directory/gruvbox
git clone $repo_powerline $directory/powerline

echo "# Downloading emails"
mbsync -a
notmuch new
