get_spell(){
    lang=$1
    mkdir ~/.config/nvim/spell --parent
    curl -o ~/.config/nvim/spell/$lang.utf-8.spl http://ftp.vim.org/pub/vim/runtime/spell/$lang.utf-8.spl
}

symlink_config () {

    dotfiles=~/dotfiles/nvim
    directory_config=~/.config/nvim
    vimspector_home=~/.local/share/nvim/site/pack/packer/start/vimspector

    mkdir $directory_config --parents
    rm $directory_config/init.vim
    rm $directory_config/after/queries/python -r
    rm $directory_config/lua -r
    rm $directory_config/ftplugin -r
    rm $vimspector_home/configurations

    mkdir $directory_config/after
    mkdir $directory_config/after/queries
    mkdir $directory_config/after/queries/python

    ln $dotfiles/init.vim $directory_config/init.vim --symbolic
    ln $dotfiles/after/queries/python/highlights.scm $directory_config/after/queries/python/highlights.scm --symbolic
    ln $dotfiles/lua $directory_config/lua --symbolic
    ln $dotfiles/ftplugin $directory_config/ftplugin --symbolic
    ln $dotfiles/vimspector/configurations $vimspector_home/configurations --symbolic
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
