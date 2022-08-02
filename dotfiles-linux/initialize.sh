function clone() {
    git clone --bare $1 $2
}

function checkout() {
    git --work-tree=$HOME --git-dir=$1 checkout -f
}

github="https://github.com/BartSte" 

base="$github/dotfiles.git" 
base_dir="$HOME/dotfiles.git"

lin="$github/dotfiles-linux.git"
lin_dir="$HOME/dotfiles-linux.git"

sec="$github/dotfiles-secret.git"
sec_dir="$HOME/dotfiles-secret.git"

echo "# Installing git"
sudo  pacman -S git exa inetutils

echo "# Clone BartSte/dotfiles.git as a bare repository"
clone $base $base_dir 
checkout $base_dir

echo "# Clone BartSte/dotfiles-linux.git as a bare repository"
clone $lin $lin_dir 
checkout $lin_dir

echo "# If you have permission: clone BartSte/dotfiles-secret.git as a bare repository"
clone $sec $sec_dir 
checkout $sec_dir

echo "Enable 'running_wsl' function"
source ~/.bashrc
bash ~/dotfiles-linux/wsl/main.sh

echo "# Please complete the file ~/dotfiles-linux/config.sh"
echo "# Next, run the ~/dotfiles-linux/main.sh"
