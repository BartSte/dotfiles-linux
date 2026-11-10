#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
for program in tmux nvim key2pane; do
    if ! command -v "$program" >/dev/null; then
        printf 'SKIP: tmux open integration (%s unavailable)\n' "$program"
        exit 0
    fi
done
test_directory=$(mktemp -d)
socket="$test_directory/tmux.sock"
cleanup() {
    tmux -S "$socket" kill-server 2>/dev/null || true
    rm -rf "$test_directory"
}
trap cleanup EXIT
export OPEN_TEST_REAL_NVIM OPEN_TEST_REAL_KEY2PANE
OPEN_TEST_REAL_NVIM=$(command -v nvim)
OPEN_TEST_REAL_KEY2PANE=$(command -v key2pane)
export OPEN_TEST_CONFIG="$repo_root/key2pane/config.json"
export OPEN_TEST_LOG="$test_directory/key2pane.log"
mkdir "$test_directory/bin"
cat > "$test_directory/bin/nvim" <<'STUB'
#!/usr/bin/env bash
exec "$OPEN_TEST_REAL_NVIM" -u NONE -i NONE -n "$@"
STUB
cat > "$test_directory/bin/key2pane" <<'STUB'
#!/usr/bin/env bash
exec "$OPEN_TEST_REAL_KEY2PANE" --config "$OPEN_TEST_CONFIG" --logfile "$OPEN_TEST_LOG" "$@"
STUB
chmod +x "$test_directory/bin/"*
export PATH="$test_directory/bin:$PATH" TERM=xterm-256color
unset OPEN_LOG_FILE OPEN_LOG_LEVEL
source_pane=$(tmux -S "$socket" -f /dev/null new-session -d -P -F '#{pane_id}' \
    -s open-test -c "$test_directory" 'sleep 120')
export TMUX="$socket,0,0" TMUX_PANE="$source_pane"
editor=$(tmux new-window -d -P -F '#{pane_id}' -n editor nvim)
filename="$test_directory/space ' | name.txt"
printf 'First line.\nSecond line.\n' > "$filename"

wait_for_file() {
    local count
    for ((count=0; count<100; count++)); do
        [[ ! -f $1 ]] || return 0
        sleep 0.05
    done
    printf 'FAIL: Neovim did not write its buffer state\n' >&2
    tmux capture-pane -p -t "$editor" >&2
    exit 1
}

check_buffer() {
    local result="$test_directory/result"
    rm -f "$result"
    tmux send-keys -t "$editor" Escape
    tmux send-keys -t "$editor" -l \
        ":lua vim.fn.writefile({vim.fn.expand('%:p'), tostring(vim.fn.line('.')), tostring(vim.fn.col('.'))}, '$result')"
    tmux send-keys -t "$editor" Enter
    wait_for_file "$result"
    printf '%s\n2\n3\n' "$filename" > "$test_directory/expected"
    cmp "$test_directory/expected" "$result"
}

# Wait for the editor to accept commands before testing reuse.
for ((attempt=0; attempt<100; attempt++)); do
    [[ $(tmux display-message -p -t "$editor" '#{pane_current_command}') != nvim ]] || break
    sleep 0.05
done
tmux send-keys -t "$editor" i
"$repo_root/bin/open" "$filename:2:3"
[[ $(tmux display-message -p '#{pane_id}') == "$editor" ]]
check_buffer

# With no editor, preserve the source process and start Neovim in its window.
tmux kill-pane -t "$editor"
"$repo_root/bin/open" "$filename:2:3"
editor=$(tmux display-message -p '#{pane_id}')
[[ $editor != "$source_pane" ]]
[[ $(tmux display-message -p -t "$editor" '#{window_id}') == \
    "$(tmux display-message -p -t "$source_pane" '#{window_id}')" ]]
[[ $(tmux display-message -p -t "$source_pane" '#{pane_current_command}') == sleep ]]
check_buffer
printf 'PASS: real tmux and Neovim editor reuse, selection, and fallback\n'
