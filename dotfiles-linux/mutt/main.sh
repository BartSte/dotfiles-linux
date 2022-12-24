. ~/dotfiles-linux/mutt/helpers.bash

echo "# Mutt"
repo_gruvbox=https://git.sthu.org/repos/mutt-gruvbox.git 
repo_powerline=https://github.com/sheoak/neomutt-powerline-nerdfonts.git
directory=~/.config/neomutt

install_theme $repo_gruvbox $directory/gruvbox
install_theme $repo_powerline $directory/powerline
