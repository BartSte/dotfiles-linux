. ~/dotfiles-linux/dependencies/helpers.sh
. ~/dotfiles-linux/dependencies/deps.sh

echo "# Dependencies"
sudo pacman -Syu --noconfirm
sudo pacman -Syy --noconfirm
sudo pacman -S --needed base-devel --noconfirm
install_yay
install_dependencies "${dependencies[@]}"
install_dependencies_aur "${dependencies_aur[@]}"
install_node_js
