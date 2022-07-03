function clone_gruvbox() {
    echo "Get gruvbox theme"
    git clone https://git.sthu.org/repos/mutt-gruvbox.git ~/.mutt/gruvbox
}

function copy_firefeh_to_bin() {
    echo "Make firefeh executable"
    sudo cp ~/dotfiles-linux/mutt/firefeh /usr/bin/firefeh
    sudo chmod u+x /usr/bin/firefeh
}

echo "# Mutt"
copy_firefeh_to_bin
clone_gruvbox
