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

secret() {
    git --git-dir=$HOME/dotfiles-secret.git/ --work-tree=$HOME "$@"
}

secrets() {
    secret status --untracked-files=no --short
}

dot() {
    local exit_status=0

    echo "Base:"
    base "$@" || exit_status=$?
    echo -e
    echo -e "Linux:"
    lin "$@" || exit_status=$?
    if [[ -d $HOME/dotfiles-arch.git ]]; then
        echo -e
        echo -e "Arch:"
        linarch "$@" || exit_status=$?
    fi
    if [[ -d $HOME/dotfiles-pi.git ]]; then
        echo -e
        echo -e "Pi:"
        linpi "$@" || exit_status=$?
    fi
    if [[ -d $HOME/dotfiles-secret.git ]]; then
        echo -e
        echo -e "Secret:"
        secret "$@" || exit_status=$?
    fi

    return $exit_status
}

shorten_stdout() {
    sed 's/(use -u .*)//'
}

_dot_commit_repo() {
    setopt localoptions pipefail

    local label=$1
    local git_command=$2
    local status_command=$3
    local worktree=$4
    local message=$5

    echo "$label"
    "$git_command" add "$worktree" || return
    "$status_command" || return

    if "$git_command" diff --cached --quiet; then
        echo "Nothing to commit"
        return 0
    fi

    "$git_command" commit --untracked-files=no -m "$message" | shorten_stdout
}

dotc() {
    local message="$*"
    if [[ -z $message ]]; then
        echo "Usage: dotc <commit message>" >&2
        return 2
    fi

    /usr/bin/find "$HOME/dotfiles" -type f \
        \( -name nvim.shada -o -name Session.vim \) -delete || return

    # Cannot be linked as it is being replaced by Lazy instead of altered.
    cp -u "$HOME/.config/nvim/lazy-lock.json" "$HOME/dotfiles/nvim/lazy-lock.json" || return

    _dot_commit_repo 'Base:' base bases "$HOME/dotfiles" "$message" || return

    /usr/bin/find "$HOME/dotfiles-linux" -type f \
        \( -name nvim.shada -o -name Session.vim \) -delete || return
    echo
    _dot_commit_repo 'Linux:' lin lins "$HOME/dotfiles-linux" "$message" || return

    if [[ -d ~/dotfiles-arch.git ]]; then
        echo
        _dot_commit_repo 'Arch:' linarch linarchs "$HOME/dotfiles-arch" "$message" || return
    fi

    if [[ -d ~/dotfiles-pi.git ]]; then
        echo
        _dot_commit_repo 'Pi:' linpi linpis "$HOME/dotfiles-pi" "$message" || return
    fi

    if [[ -d ~/dotfiles-secret.git ]]; then
        echo
        _dot_commit_repo 'Secret:' secret secrets "$HOME/dotfiles-secret" "$message" || return
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

    if [[ -d $HOME/dotfiles-secret.git ]]; then
        echo $'\nSecret':
        secrets
    fi
}

indent() {
    sed -e 's/^/    /'
}

dotu() {
    setopt localoptions pipefail

    echo "Commit"
    dotc "Automatic Update" 2>&1 | indent || return
    echo "\nPull"
    dot pull 2>&1 | indent || return
    echo "\nPush"
    dot push 2>&1 | indent
}
