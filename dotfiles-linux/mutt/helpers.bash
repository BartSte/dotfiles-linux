install_theme() {
    repo=$1
    directory=$2
    git clone $repo $directory
}
