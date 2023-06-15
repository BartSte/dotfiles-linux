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
    rm $directory_config/init.vim
    rm $directory_config/lua -r
    rm $directory_config/ftplugin -r

    ln $dotfiles/init.vim $directory_config/init.vim --symbolic
    ln $dotfiles/lua $directory_config/lua --symbolic
    ln $dotfiles/ftplugin $directory_config/ftplugin --symbolic
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
