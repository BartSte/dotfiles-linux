#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
export XDG_CACHE_HOME="$test_directory/cache space"
export TMUX_SESSION_DIRS_CONFIG="$test_directory/dirs"
export TEST_GIT_CALLS="$test_directory/git-calls"
export TEST_REAL_GIT
TEST_REAL_GIT=$(command -v git)
picker="$repo_root/bin/tsp-picker"
project="$test_directory/projects/repo one"
mkdir -p "$project" "$test_directory/bin"
git -C "$project" init -q -b main
printf '%s\n' "$test_directory/projects" > "$TMUX_SESSION_DIRS_CONFIG"
cat > "$test_directory/bin/git" <<'STUB'
#!/usr/bin/env bash
printf 'call\n' >> "$TEST_GIT_CALLS"
exec "$TEST_REAL_GIT" "$@"
STUB
cat > "$test_directory/bin/fzf" <<'STUB'
#!/usr/bin/env bash
input=$(cat)
[[ ${TEST_CANCEL:-false} == false ]] || exit 130
printf '%s\n' "${input%%$'\n'*}"
STUB
chmod +x "$test_directory/bin/"*
export PATH="$test_directory/bin:$PATH"

# The first scan fills the cache; a warm selection runs no Git commands.
[[ $("$picker") == "$project" ]]
first_calls=$(wc -l < "$TEST_GIT_CALLS")
((first_calls > 0))
[[ $("$picker") == "$project" ]]
[[ $(wc -l < "$TEST_GIT_CALLS") == "$first_calls" ]]
cache_files=("$XDG_CACHE_HOME/tsp-picker/"*.tsv)
[[ ${#cache_files[@]} == 1 ]]

# A new repository stays outside the cached snapshot until an explicit refresh.
second_project="$test_directory/projects/repo two"
mkdir -p "$second_project"
"$TEST_REAL_GIT" -C "$second_project" init -q -b main
[[ $("$picker" --list) == *"$second_project"* ]]
[[ $(cat "${cache_files[0]}") != *"$second_project"* ]]
[[ $("$picker" --refresh) == *"$second_project"* ]]
[[ $(cat "${cache_files[0]}") == *"$second_project"* ]]

# Expired snapshots refresh automatically, including branch labels.
"$TEST_REAL_GIT" -C "$project" symbolic-ref HEAD refs/heads/changed
touch -d '2 minutes ago' "${cache_files[0]}"
selection=$("$picker")
[[ "$selection" == "$project" || "$selection" == "$second_project" ]]
[[ $(cat "${cache_files[0]}") == *'[changed]'* ]]

# Changed configuration cannot reuse another configuration's results.
printf '%s\n' "$second_project" > "$TMUX_SESSION_DIRS_CONFIG"
[[ $("$picker") == "$second_project" ]]
cache_files=("$XDG_CACHE_HOME/tsp-picker/"*.tsv)
[[ ${#cache_files[@]} == 2 ]]

# Cancellation and deleted cached directories never produce a selected path.
export TEST_CANCEL=true
[[ -z $("$picker") ]]
unset TEST_CANCEL
rm -rf "$second_project"
if "$picker" > "$test_directory/output" 2> "$test_directory/error"; then
    printf 'FAIL: a deleted cached directory was accepted\n' >&2
    exit 1
fi
[[ ! -s "$test_directory/output" ]]
[[ $(cat "$test_directory/error") == *'Ctrl-R'* ]]
[[ -z $("$picker" --refresh) ]]
[[ -z $("$picker") ]]

printf 'PASS: warm cache, fresh listing, refresh, expiry, configuration changes, cancellation, deleted paths, and empty results\n'
