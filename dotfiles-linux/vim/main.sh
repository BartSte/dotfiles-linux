function install_vim_plug () {
    echo "Instal vim plug"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim -c PlugInstall\|qa!
}

sym_link_init_vim () {
    ln ~/init.vim ~/.config/nvim/init.vim --symbolic
}

echo "# Vim"
install_vim_plug
sym_link_init_vim 
