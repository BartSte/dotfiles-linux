if [[ -z "$TMUX" ]]; then
    return
fi


dir=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
name=$(tmux display-message -p '#S')
if [[ "$name" == "snapshot" ]]; then
    source $dir/snapshotrc.zsh
fi

