function install_vim_plug () {
    echo "Instal vim plug"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim -c PlugInstall\|qa!
}

function install_nvim_plug () {
    echo "Instal nvim plug"
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    nvim -c PlugInstall\|qa!
}

sym_link_init_vim () {
    mkdir ~/.config/nvim
    rm ~/.config/nvim/init.vim
    ln ~/.vim/init.vim ~/.config/nvim/init.vim --symbolic
}

echo "# Vim"
install_vim_plug
install_nvim_plug
sym_link_init_vim 
pip install pynvim
