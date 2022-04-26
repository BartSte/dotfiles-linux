. $HOME/dotfiles-linux/config.sh
. $HOME/dotfiles-linux/helpers.sh


sudo apt update
add_ppa_python
add_ppa_vim

install_dependencies $dependencies
install_font
install_node_js
install_vim_plug
build_fzf
