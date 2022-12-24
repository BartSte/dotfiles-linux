install_icons() {
    repo=https://github.com/sheoak/neomutt-powerline-nerdfonts.git
    directory=$1

    mkdir $directory
    git clone $repo $directory/powerline
}
