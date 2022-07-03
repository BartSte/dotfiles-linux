. ~/dotfiles-linux/dependencies/helpers.sh
. ~/dotfiles-linux/config.sh

sudo apt update
sudo apt upgrade
sudo apt install 
add_ppa_alacritty
add_ppa_python
install_dependencies "${dependencies[@]}"
install_node_js
