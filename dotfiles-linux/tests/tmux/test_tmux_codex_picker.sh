#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
subject="$repo_root/bin/tmux-codex-picker"
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT

fake_bin="$test_directory/bin"
event_log="$test_directory/events"
mkdir -p "$fake_bin"
: > "$event_log"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_log_contains() {
    local expected=$1
    grep -Fxq "$expected" "$event_log" || fail "event log does not contain: $expected"
}

cat > "$fake_bin/tmux" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
    list-panes)
        if [[ ${TEST_EMPTY_LIST:-0} != 1 ]]; then
            printf '%%7\tproject one:2.0\tproject one | codex | ~/code/project one | Ready | Fix tests\n'
            printf '%%9\tproject-two:3.1\tproject-two | codex | ~/code/project-two | Thinking | Add feature\n'
        fi
        ;;
    display-message)
        if [[ ${2:-} == -p ]]; then
            preview_count_file="${TEST_PREVIEW_COUNT_FILE:?}"
            preview_count=$(cat "$preview_count_file")
            preview_count=$((preview_count + 1))
            printf '%s\n' "$preview_count" > "$preview_count_file"
            ((preview_count <= 2))
            exit
        fi
        printf '%s\n' "$*" >> "$TEST_EVENT_LOG"
        ;;
    capture-pane)
        printf 'Preview frame\n'
        ;;
    switch-client)
        printf '%s\n' "$*" >> "$TEST_EVENT_LOG"
        ;;
    *)
        printf 'Unexpected tmux command: %s\n' "$*" >&2
        exit 1
        ;;
esac
SH

cat > "$fake_bin/fzf" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

printf 'fzf %s\n' "$*" >> "$TEST_EVENT_LOG"
if [[ ${TEST_CANCEL_FZF:-0} == 1 ]]; then
    exit 130
fi
IFS= read -r selection
printf '%s\n' "$selection"
SH

chmod +x "$fake_bin/tmux" "$fake_bin/fzf"
export PATH="$fake_bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export TEST_EVENT_LOG="$event_log"
export TEST_PREVIEW_COUNT_FILE="$test_directory/preview-count"
printf '0\n' > "$TEST_PREVIEW_COUNT_FILE"

list_output=$($subject --list)
[[ $list_output == *$'%7\t[Ready]      project one:2.0'* ]] || fail 'list output lost a ready pane with spaces'
[[ $list_output == *'Fix tests'* ]] || fail 'list output lost the task title'
[[ $list_output == *$'%9\t[Thinking]   project-two:3.1'* ]] || fail 'list output lost the thinking pane'

: > "$event_log"
$subject
assert_log_contains 'switch-client -t %7'
grep -Fq 'tmux-codex-picker --preview {1}' "$event_log" || fail 'fzf preview command is missing'
grep -Fq 'ctrl-s:execute-silent' "$event_log" || fail 'fzf live-preview toggle is missing'

preview_state_file="$test_directory/preview-state"
printf 'live\n' > "$preview_state_file"
export TMUX_CODEX_PREVIEW_STATE="$preview_state_file"
export TMUX_CODEX_PREVIEW_INTERVAL=0.01
printf '0\n' > "$TEST_PREVIEW_COUNT_FILE"
preview_output=$($subject --preview %7)
[[ $preview_output == *'[LIVE preview - Ctrl-s to toggle]'* ]] || fail 'live-preview status is missing'
[[ $preview_output == *'Preview frame'* ]] || fail 'live pane content is missing'

$subject --toggle-preview
[[ $(< "$preview_state_file") == frozen ]] || fail 'preview did not freeze'
$subject --toggle-preview
[[ $(< "$preview_state_file") == live ]] || fail 'preview did not resume'
unset TMUX_CODEX_PREVIEW_INTERVAL TMUX_CODEX_PREVIEW_STATE

: > "$event_log"
export TEST_CANCEL_FZF=1
$subject
unset TEST_CANCEL_FZF
[[ ! -s $event_log || $(grep -c '^switch-client ' "$event_log" || true) -eq 0 ]] || fail 'cancel switched panes'

: > "$event_log"
export TEST_EMPTY_LIST=1
$subject
unset TEST_EMPTY_LIST
assert_log_contains 'display-message No Codex panes found'

if $subject --invalid 2>/dev/null; then
    fail 'invalid argument returned success'
fi

printf 'PASS: tmux Codex picker\n'
