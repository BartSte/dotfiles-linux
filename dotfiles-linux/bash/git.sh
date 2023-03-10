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

sec() {
    git --git-dir=$HOME/dotfiles-secret.git/ --work-tree=$HOME "$@"
}

secs() {
    sec status --untracked-files=no --short
}

dot() {
    git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME "$@"
    git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME "$@"
    git --git-dir=$HOME/dotfiles-secret.git/ --work-tree=$HOME "$@"
}

shorten_stdout(){
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
    common_args="commit --untracked-files=no -a"

    echo 'Base:'
    base add ~/dotfiles
    bases
    base $common_args -m "$message" | shorten_stdout

    echo $'\nLinux'
    lin add ~/bin
    lin add ~/dotfiles-linux
    lins
    lin $common_args -m "$message" | shorten_stdout

    echo $'\nSecret'
    sec add ~/dotfiles-secret
    secs
    sec $common_args -m "$message" | shorten_stdout
}

dots() {
    echo Base: 
    bases

    echo $'\nLinux': 
    lins 

    echo $'\nSec': 
    secs
}

dotp() {
    dot push
}
