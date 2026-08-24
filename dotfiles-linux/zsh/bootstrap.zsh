save-source() {
    local file=$1
    if [[ -f $file ]]; then
        source "$file" 2>/dev/null || echo "WARNING: $file could not be sourced" >&2
    else
        echo "WARNING: $file does not exist" >&2
    fi
}

add_to_path() {
    local dir
    for dir in "$@"; do
        if [[ -d $dir && ":${PATH:-}:" != *":$dir:"* ]]; then
            PATH="$dir${PATH:+:$PATH}"
        fi
    done
    export PATH
}

append_to_path() {
    local dir
    for dir in "$@"; do
        if [[ -d $dir && ":${PATH:-}:" != *":$dir:"* ]]; then
            PATH="${PATH:+$PATH:}$dir"
        fi
    done
    export PATH
}

normalize_path() {
    local remaining="${PATH:-}:" dir normalized=

    while [[ -n $remaining ]]; do
        dir=${remaining%%:*}
        remaining=${remaining#*:}

        [[ -n $dir && -d $dir ]] || continue

        # WSL can import the entire Windows PATH. Keep Linux command lookup fast;
        # wsl.zsh explicitly adds the few Windows directories that are useful.
        if [[ -n ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} && $dir == /mnt/[[:alpha:]]/* ]]; then
            continue
        fi

        if [[ ":$normalized:" != *":$dir:"* ]]; then
            normalized="${normalized:+$normalized:}$dir"
        fi
    done

    export PATH=$normalized
}
