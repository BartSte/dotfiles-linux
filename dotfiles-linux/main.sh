. ~/dotfiles-linux/wsl/helpers

~/dotfiles-linux/git/main.sh
~/dotfiles-linux/dependencies/main.sh
~/dotfiles-linux/fonts/main.sh
~/dotfiles-linux/vim/main.sh
~/dotfiles-linux/fzf/main.sh
~/dotfiles-linux/mutt/main.sh

if running_wsl; then
    ~/dotfiles-linux/wsl/main.sh
else
    ~/dotfiles-linux/i3/main.sh
fi
