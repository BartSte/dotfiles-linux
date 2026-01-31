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

linarch() {
    git --git-dir=$HOME/dotfiles-arch.git/ --work-tree=$HOME "$@"
}

linarchs() {
    linarch status --untracked-files=no --short
}

linpi() {
    git --git-dir=$HOME/dotfiles-pi.git/ --work-tree=$HOME "$@"
}

linpis() {
    linpi status --untracked-files=no --short
}

dot() {
    echo "Base:"
    git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME "$@"
    echo -e
    echo -e "Linux:"
    git --git-dir=$HOME/dotfiles-linux.git/ --work-tree=$HOME "$@"
    if [[ -d $HOME/dotfiles-arch.git ]]; then
        echo -e
        echo -e "Arch:"
        linarch "$@"
    fi
    if [[ -d $HOME/dotfiles-pi.git ]]; then
        echo -e
        echo -e "Pi:"
        linpi "$@"
    fi
}

shorten_stdout() {
    sed 's/(use -u .*)//'
}

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

    if [[ -d ~/dotfiles-arch.git ]]; then
        echo $'\nArch'
        linarch add ~/dotfiles-arch
        linarchs
        linarch commit --untracked-files=no -a -m "$message" | shorten_stdout
    fi

    if [[ -d ~/dotfiles-pi.git ]]; then
        echo $'\nPi'
        linpi add ~/dotfiles-pi
        linpis
        linpi commit --untracked-files=no -a -m "$message" | shorten_stdout
    fi
}

dots() {
    echo "Git status\n"
    echo Base:
    bases

    echo $'\nLinux':
    lins

    if [[ -d $HOME/dotfiles-arch.git ]]; then
        echo $'\nArch':
        linarchs
    fi

    if [[ -d $HOME/dotfiles-pi.git ]]; then
        echo $'\nPi':
        linpis
    fi
}

indent() {
    sed -e 's/^/    /'
}

dotu() {
    echo "Commit"
    dotc "Automatic Update" 2>&1 | indent
    echo "\nPull"
    dot pull 2>&1 | indent
    echo "\nPush"
    dot push 2>&1 | indent
}
