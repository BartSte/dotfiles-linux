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
    echo "Base:"
    git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME "$@"
    echo -e
    echo -e "Linux:"
    git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME "$@"
    echo -e
    echo -e "Secret:"
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

    echo 'Base:'
    base add ~/dotfiles
    bases
    base commit --untracked-files=no -a -m "$message" | shorten_stdout

    echo $'\nLinux'
    lin add ~/bin
    lin add ~/dotfiles-linux
    lins
    lin commit --untracked-files=no -a -m "$message" | shorten_stdout

    echo $'\nSecret'
    sec add ~/dotfiles-secret
    secs
    sec commit --untracked-files=no -a -m "$message" | shorten_stdout
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
