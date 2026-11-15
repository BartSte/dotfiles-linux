#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
for program in tmux zsh; do
    if ! command -v "$program" >/dev/null; then
        printf 'SKIP: Ctrl+Enter integration (%s unavailable)\n' "$program"
        exit 0
    fi
done

test_directory=$(mktemp -d)
socket="$test_directory/tmux.sock"
cleanup() {
    tmux -S "$socket" kill-server 2>/dev/null || true
    rm -rf -- "$test_directory"
}
trap cleanup EXIT

cat > "$test_directory/.zshrc" <<'ZSH'
source "$CTRL_ENTER_TEST_ROOT/zsh/vi-mode.zsh"
source "$CTRL_ENTER_TEST_ROOT/zsh/bindings.zsh"
PROMPT='READY> '
RPROMPT=''
KEYTIMEOUT=1
# Ensure the test cannot pass because tmux downgraded Ctrl+Enter to Enter.
bindkey -M viins '^M' undefined-key
bindkey -M vicmd '^M' undefined-key
ZSH

tmux -S "$socket" -f /dev/null new-session -d -s ctrl-enter \
    -e "ZDOTDIR=$test_directory" -e "CTRL_ENTER_TEST_ROOT=$repo_root" 'zsh -di'
tmux -S "$socket" set-option -s extended-keys on
tmux -S "$socket" set-option -s extended-keys-format csi-u

wait_for_prompt() {
    local attempt
    for ((attempt = 0; attempt < 100; attempt++)); do
        if tmux -S "$socket" capture-pane -p | rg -q 'READY>'; then
            return 0
        fi
        sleep 0.05
    done
    printf 'FAIL: Zsh prompt did not appear\n' >&2
    tmux -S "$socket" capture-pane -p >&2
    exit 1
}

wait_for_output() {
    local file=$1 attempt
    for ((attempt = 0; attempt < 100; attempt++)); do
        [[ ! -f $file ]] || return 0
        sleep 0.05
    done
    printf 'FAIL: Ctrl+Enter did not execute the command\n' >&2
    tmux -S "$socket" capture-pane -p >&2
    exit 1
}

wait_for_prompt
for format in csi-u xterm; do
    tmux -S "$socket" set-option -s extended-keys-format "$format"
    for mode in viins vicmd; do
        output="$test_directory/$format $mode"
        printf -v command_line "printf 'hello world\\\\n' > %q" "$output"
        tmux -S "$socket" send-keys -l "$command_line"
        if [[ $mode == vicmd ]]; then
            tmux -S "$socket" send-keys Escape
            sleep 0.05
        fi
        tmux -S "$socket" send-keys C-Enter
        wait_for_output "$output"
        [[ $(< "$output") == 'hello world' ]]
    done
done

printf 'PASS: Ctrl+Enter executes commands through tmux in both Vi modes and key formats.\n'
