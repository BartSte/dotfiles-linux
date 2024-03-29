save-source() {
    local file=$1
    if [ -f "$file" ]; then
        source $file
    else
        echo "WARNING: $file does not exist" >&2
    fi
}

add_to_path() {
    for dir in "$@"; do
        if [[ ":$PATH:" != *":$dir:"* ]]; then
            export PATH="$dir:$PATH"
        fi
    done
}

append_to_path() {
    for dir in "$@"; do
        if [[ ":$PATH:" != *":$dir:"* ]]; then
            export PATH="$PATH:$dir"
        fi
    done
}

_zshrc_log() {
    if ${_zshrc_verbose:-false}; then
        echo "$@" 2>&1
    fi
}
_zshrc_verbose=${_zshrc_verbose:-false}
