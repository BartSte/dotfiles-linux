install_theme() {
    repo=$1
    directory=$2
    mkdir $directory --parents
    git clone $repo $directory
}
