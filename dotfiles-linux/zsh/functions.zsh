################################################################################
# Use fzf to select multiple processes to kill
################################################################################
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}') || return
    xargs kill -"${1:-9}" <<<"$pid"
}

################################################################################
# Sync all programs
################################################################################
fullsync() {
    echo "### Syncing rbw"
    rbw unlock && rbw sync

    echo "\n### Syncing dotfiles"
    dotu

    echo "\n### Syncing calendar"
    mycalsync

    echo "\n### Syncing mail"
    mailsync

    echo "\n### Syncing dropbox"
    rclone bisync dropbox: ~/dropbox
}

###############################################################################
# Run aider chat
# Before, specify host and project settings are loaded.
###############################################################################
chat() {
    local dir
    dir=$HOME/dotfiles-linux/aider
    save-source $dir/host_settings.zsh
    save-source $dir/$PROJECTRC.zsh
    aider
}

###############################################################################
# Run aider --message with a prompts from bartste-prompts
###############################################################################
ai() {
    usage="Usage: ai [options] command file1 file2 ...

    Runs 'aider --yes-always --message <message> file1 file2 ...' where
    <message> is retrieved from bartste-prompts.

    Options:
    -h, --help      Show this help message.
    -f, --filetype  Specify a file type for the prompt.
    -q, --quiet     Disable output to stderr."""

    local prompt file_type quiet command files message
    while (("$#")); do
        case $1 in
        -h | --help)
            echo "$usage"
            return
            ;;
        -f | --filetype)
            file_type=$2
            shift 2
            ;;
        -q | --quiet)
            quiet="--quiet"
            shift
            ;;
        *)
            if [[ -z "$command" ]]; then
                command=$1
            else
                files+=("$1")
            fi
            shift
            ;;
        esac
    done

    if [[ -z "$command" ]]; then
        echo "Error: No command specified."
        echo "$usage"
        return 1
    fi

    # TODO
}
