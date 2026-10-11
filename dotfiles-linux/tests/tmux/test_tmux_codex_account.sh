#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
subject="$repo_root/bin/tmux-codex-account"
test_directory=$(mktemp -d)
process_ids=()
cleanup() {
    if ((${#process_ids[@]})); then
        kill "${process_ids[@]}" 2>/dev/null || true
        wait "${process_ids[@]}" 2>/dev/null || true
    fi
    rm -rf "$test_directory"
}
trap cleanup EXIT

test_home="$test_directory/home space"
mkdir -p "$test_home/.codex" "$test_home/.codex-personal"
# A real process provides procfs records without any Codex authentication.
cp "$(command -v sleep)" "$test_directory/codex"

assert_account() {
    local expected=$1 process_id
    shift
    "$@" "$test_directory/codex" 60 &
    process_id=$!
    process_ids+=("$process_id")
    # Wait until exec replaces the shell process.
    for ((attempt = 0; attempt < 100; attempt++)); do
        [[ $(< "/proc/$process_id/comm") == codex ]] && break
        sleep 0.01
    done
    [[ $("$subject" "$process_id") == "$expected" ]]
}

assert_account 'Codex: Work' env -u CODEX_HOME HOME="$test_home"
assert_account 'Codex: Personal' env HOME="$test_home" CODEX_HOME="$test_home/.codex-personal"
assert_account 'Codex: Work' env HOME="$test_home" CODEX_HOME="$test_home/.codex-personal/../.codex"
assert_account 'Codex: Custom' env HOME="$test_home" CODEX_HOME="$test_home/custom codex"
# A parent shell resolves its Codex child, regardless of the current directory.
[[ $("$subject" "$$") == 'Codex: Work' ]]
[[ -z $("$subject" 999999999) ]]
for argument in '' invalid -1; do
    if "$subject" "$argument" > /dev/null 2>&1; then
        printf 'FAIL: invalid PID was accepted\n' >&2
        exit 1
    fi
done
if "$subject" > /dev/null 2>&1; then
    printf 'FAIL: missing PID was accepted\n' >&2
    exit 1
fi

printf 'PASS: Codex account labels, overrides, parent shells, spaces, and invalid input\n'
