base() {
    git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME "$@"
}

bases() {
    base status --untracked-files=no --short
}

lin() {
    git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME "$@"
}

lins() {
    lin status --untracked-files=no --short
}

dot() {
    echo "Base:"
    git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME "$@"
    echo -e
    echo -e "Linux:"
    git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME "$@"
}

shorten_stdout() {
    sed 's/(use -u .*)//'
}

# Mass commit to all dotfiles layers.
# All command line args are concatinated into a commit message
#######################################
# Remove (use -u to show untracked-files)
# from the sdout
#######################################
dotc() {
    message="'$*'"

    echo 'Base:'
    rm $(fd nvim.shada ~/dotfiles --type f) &>/dev/null
    base add ~/dotfiles
    bases
    base commit --untracked-files=no -a -m "$message" | shorten_stdout

    echo $'\nLinux'
    rm $(fd nvim.shada ~/dotfiles-linux --type f) &>/dev/null
    lin add ~/dotfiles-linux
    lins
    lin commit --untracked-files=no -a -m "$message" | shorten_stdout
}

dots() {
    echo "Git status\n"
    echo Base:
    bases

    echo $'\nLinux':
    lins
}

indent() {
    sed -e 's/^/    /'
}

# Dot update: commit, pull, push
dotu() {
    echo "Commit"
    dotc "Automatic Update" | indent
    echo "\nPull"
    dot pull | indent
    echo "\nPush"
    dot push | indent
}
