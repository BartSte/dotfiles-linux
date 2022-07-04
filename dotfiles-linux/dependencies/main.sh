. ~/dotfiles-linux/dependencies/helpers.sh
. ~/dotfiles-linux/dependencies/deps.sh

echo "# Dependencies"
sudo apt update -y
sudo apt upgrade -y
add_ppa_alacritty
add_ppa_python
install_dependencies "${dependencies[@]}"
install_node_js
