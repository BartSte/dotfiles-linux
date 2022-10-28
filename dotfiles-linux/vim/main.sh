sym_link_init_vim () {
    mkdir ~/.config/nvim
    rm ~/.config/nvim/init.vim
    ln ~/dotfiles/vim/init.vim ~/.config/nvim/init.vim --symbolic
}

echo "# Vim"
sym_link_init_vim 
pip install pynvim
