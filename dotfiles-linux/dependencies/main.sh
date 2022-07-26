. ~/dotfiles-linux/dependencies/helpers.sh
. ~/dotfiles-linux/dependencies/deps.sh

echo "# Dependencies"
sudo pacman -Syu
sudo pacman -Syy
sudo pacman -S --needed base-devel
install_yay
install_dependencies "${dependencies[@]}"
install_dependencies_aur "${dependencies_aur[@]}"
install_node_js
