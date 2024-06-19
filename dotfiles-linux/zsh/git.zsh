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
    /usr/bin/rm $(fd nvim.shada ~/dotfiles --type f) &>/dev/null
    /usr/bin/rm $(fd Session.vim ~/dotfiles --type f) &>/dev/null

    # Cannot be linked as it is being replaced by Lazy instead of altered.
    cp -u ~/.config/nvim/lazy-lock.json ~/dotfiles/nvim/lazy-lock.json

    base add ~/dotfiles
    bases
    base commit --untracked-files=no -a -m "$message" | shorten_stdout

    echo $'\nLinux'
    /usr/bin/rm $(fd nvim.shada ~/dotfiles-linux --type f) &>/dev/null
    /usr/bin/rm $(fd Session.vim ~/dotfiles-linux --type f) &>/dev/null

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
    dotc "Automatic Update" 2>&1 | indent
    echo "\nPull"
    dot pull 2>&1 | indent
    echo "\nPush"
    dot push 2>&1 | indent
}
