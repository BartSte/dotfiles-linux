function clone() {
    git clone --bare $1 $2
}

function checkout() {
    git --work-tree=$HOME --git-dir=$1 checkout
}

github="https://github.com/BartSte" 

base="$github/dotfiles.git" 
base_dir="$HOME/dotfiles.git"

lin="$github/dotfiles-linux.git"
lin_dir="$HOME/dotfiles-linux.git"

echo "# Installing git"
sudo  pacman -S git

echo "# Clone BartSte/dotfiles.git as a bare repository"
clone $base $base_dir 
checkout $base_dir
rm "$HOME/.gitignore"
rm "$HOME/README.md"

echo "# Clone BartSte/dotfiles-linux.git as a bare repository"
clone $lin $lin_dir 
checkout $lin_dir
source ~/.bashrc

echo "# Please complete the file ~/dotfiles-linux/config.sh"
echo "# Next, run the ~/dotfiles-linux/main.sh"

