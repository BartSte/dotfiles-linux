save-source() {
    local file=$1
    if [ -f "$file" ]; then
        source $file || echo "WARNING: $file could not be sourced" >&2
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
