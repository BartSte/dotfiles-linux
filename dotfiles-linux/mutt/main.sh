function clone_gruvbox() {
    git clone https://git.sthu.org/repos/mutt-gruvbox.git ~/.mutt/gruvbox
}

function copy_firefeh_to_bin() {
    sudo cp ~/dotfiles-linux/firefeh /usr/bin/firefeh --no-clobber
    sudo chmod u+x /usr/bin/firefeh
}

copy_firefeh_to_bin
clone_gruvbox
