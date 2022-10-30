symlink_config () {
    mkdir ~/.config/nvim
    rm ~/.config/nvim/init.vim
    rm ~/.config/nvim/after -r
    rm ~/.config/nvim/lua -r

    ln ~/dotfiles/nvim/init.vim ~/.config/nvim/init.vim --symbolic
    ln ~/dotfiles/nvim/after ~/.config/nvim/after --symbolic
    ln ~/dotfiles/nvim/lua ~/.config/nvim/lua --symbolic
}

echo "# Vim"
symlink_config 
pip install pynvim
