. ~/dotfiles-linux/config.sh
. ~/dotfiles-linux/helpers.sh

sudo apt update
sudo apt install software-properties-common
init_git
add_ppa_python
add_ppa_alacritty

install_dependencies "${dependencies[@]}"
install_font
install_node_js
install_vim_plug
build_fzf

~/.mutt/main.sh
