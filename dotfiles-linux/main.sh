. ~/dotfiles-linux/config.sh
. ~/dotfiles-linux/helpers.sh

upgrade_vim
install_vim_plug
install_node_js
install_font
install_dependencies $dependencies
vim_plug_install
build_fzf
