. ~/dotfiles-linux/wsl/helpers.sh
    
echo "Installing BartSte/dotfiles-linux repository"
bash ~/dotfiles-linux/git/main.sh
bash ~/dotfiles-linux/baselayer/main.sh
bash ~/dotfiles-linux/dependencies/main.sh
bash ~/dotfiles-linux/fonts/main.sh
bash ~/dotfiles-linux/vim/main.sh
bash ~/dotfiles-linux/mutt/main.sh

if running_wsl; then
    bash ~/dotfiles-linux/wsl/main.sh
else
    bash ~/dotfiles-linux/i3/main.sh
fi
echo "Done"
