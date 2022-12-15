get_spell(){
    lang=$1
    mkdir ~/.config/nvim/spell --parent
    curl -o ~/.config/nvim/spell/$lang.utf-8.spl http://ftp.vim.org/pub/vim/runtime/spell/$lang.utf-8.spl
}
symlink_config () {
    mkdir ~/.config/nvim --parents
    rm ~/.config/nvim/init.vim
    rm ~/.config/nvim/after -r
    rm ~/.config/nvim/lua -r
    rm ~/.config/nvim/ftplugin -r

    ln ~/dotfiles/nvim/init.vim ~/.config/nvim/init.vim --symbolic
    ln ~/dotfiles/nvim/after ~/.config/nvim/after --symbolic
    ln ~/dotfiles/nvim/lua ~/.config/nvim/lua --symbolic
    ln ~/dotfiles/nvim/ftplugin ~/.config/nvim/ftplugin --symbolic
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
make_dict nl "$HOME/.local/share/nvim/dict"
make_dict en "$HOME/.local/share/nvim/dict"
get_spell nl
get_spell en
pip install pynvim
