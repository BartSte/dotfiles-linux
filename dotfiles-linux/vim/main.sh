symlink_config () {
    mkdir ~/.config/nvim
    rm ~/.config/nvim/init.vim
    rm ~/.config/nvim/after -r
    rm ~/.config/nvim/lua -r

    ln ~/dotfiles/vim/init.vim ~/.config/nvim/init.vim --symbolic
    ln ~/dotfiles/vim/after ~/.config/nvim/after --symbolic
    ln ~/dotfiles/vim/lua ~/.config/nvim/lua --symbolic
}

echo "# Vim"
symlink_config 
pip install pynvim
