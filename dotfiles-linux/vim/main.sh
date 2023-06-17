#!/bin/bash

get_spell(){
    lang=$1
    mkdir ~/.config/nvim/spell --parent
    curl -o ~/.config/nvim/spell/$lang.utf-8.spl http://ftp.vim.org/pub/vim/runtime/spell/$lang.utf-8.spl
}

symlink_config () {

    dotfiles=~/dotfiles/nvim
    directory_config=~/.config/nvim

    mkdir $directory_config --parents
    rm $directory_config/init.lua
    rm $directory_config/lua -r
    rm $directory_config/after -r
    rm $directory_config/plugin -r
    rm $directory_config/vim -r

    ln $dotfiles/init.lua $directory_config/init.lua --symbolic
    ln $dotfiles/lua $directory_config/lua --symbolic
    ln $dotfiles/after $directory_config/after --symbolic
    ln $dotfiles/plugin $directory_config/plugin --symbolic
    ln $dotfiles/vim $directory_config/vim --symbolic
}

make_dict(){
    lang=$1
    storage=$2
    file="$lang.dict"

    echo "Creating aspell dictionary $file at $storage"
    mkdir $storage --parents

    pushd .
    cd $storage
    aspell -d $lang dump master | aspell -l $lang expand > $file
    popd
}

echo "# Vim"
symlink_config 
make_dict nl "$HOME/.config/nvim/dict"
make_dict en "$HOME/.config/nvim/dict"
get_spell nl
get_spell en
pip install pynvim
