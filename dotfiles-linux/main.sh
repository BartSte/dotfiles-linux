echo "Installing BartSte/dotfiles-linux repository"

bash ~/dotfiles-linux/git/main.sh
bash ~/dotfiles-linux/dependencies/main.sh
bash ~/dotfiles-linux/wsl/main.sh
bash ~/dotfiles-linux/fonts/main.sh
bash ~/dotfiles-linux/vim/main.sh
bash ~/dotfiles-linux/gpg/main.sh
bash ~/dotfiles-linux/mutt/main.sh
bash ~/dotfiles-linux/i3/main.sh
bash ~/dotfiles-linux/kmonad/main.sh
bash ~/dotfiles-linux/davmail/main.bash

echo "Done"
