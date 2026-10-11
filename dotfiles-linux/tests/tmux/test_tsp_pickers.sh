#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
export TEST_WORKTREE_ROOT="$test_directory/worktrees space"
export TEST_OPENED="$test_directory/opened"
export TEST_PICKER_INPUT="$test_directory/picker-input"
export TMUX_SESSION_DIRS_CONFIG="$test_directory/dirs"
project="$test_directory/projects/project one"
mkdir -p "$project" "$test_directory/bin"
printf '%s\n' "$test_directory/projects" "$TEST_WORKTREE_ROOT" > "$TMUX_SESSION_DIRS_CONFIG"
sed 's|$HOME/code/worktrees|$TEST_WORKTREE_ROOT|g' "$repo_root/bin/tsp-wt" > "$test_directory/bin/tsp-wt"
sed 's|$HOME/code/worktrees|$TEST_WORKTREE_ROOT|g' "$repo_root/bin/tsp-picker" > "$test_directory/bin/tsp-picker"
cat > "$test_directory/bin/tmux" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
cat > "$test_directory/bin/tsp" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$1" > "$TEST_OPENED"
STUB
cat > "$test_directory/bin/fzf" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
cat > "$TEST_PICKER_INPUT"
[[ ${TEST_CANCEL:-false} == false ]] || exit 130
while IFS=$'\t' read -r kind value label remote; do
    if [[ "$kind" == "$TEST_SELECT_TYPE" && "$value" == "$TEST_SELECT_VALUE" &&
        "${remote:-}" == "${TEST_SELECT_REMOTE:-}" ]]; then
        printf '%s\t%s\t%s' "$kind" "$value" "$label"
        [[ -z "${remote:-}" ]] || printf '\t%s' "$remote"
        printf '\n'
        exit 0
    fi
done < "$TEST_PICKER_INPUT"
exit 1
STUB
chmod +x "$test_directory/bin/"*
export PATH="$test_directory/bin:$PATH"
branches="$repo_root/bin/tsp-branches"
projects="$test_directory/bin/tsp-picker"

git -C "$project" init -q -b main
git -C "$project" config user.name Test
git -C "$project" config user.email test@example.com
printf 'base\n' > "$project/file"
git -C "$project" add file
git -C "$project" commit -qm base
base_commit=$(git -C "$project" rev-parse HEAD)
git -C "$project" branch local-task
git -C "$project" switch -qc temporary-source
printf 'remote\n' > "$project/file"
git -C "$project" commit -qam remote
remote_commit=$(git -C "$project" rev-parse HEAD)
git -C "$project" switch -q main
git -C "$project" branch -D temporary-source > /dev/null
git -C "$project" remote add origin https://github.com/example/project.git
git -C "$project" remote add upstream https://github.com/other/project.git
git -C "$project" update-ref refs/remotes/origin/main "$base_commit"
git -C "$project" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git -C "$project" update-ref refs/remotes/origin/feature/login "$remote_commit"
git -C "$project" update-ref refs/remotes/upstream/fix/bug "$remote_commit"
printf 'uncommitted main\n' > "$project/file"

listing=$("$branches" --list "$project")
[[ "$listing" == *$'local\tmain\t[local] main'* ]]
[[ "$listing" == *$'local\tlocal-task\t[local] local-task'* ]]
[[ "$listing" == *$'remote\tfeature/login\t[remote] origin/feature/login\torigin'* ]]
[[ "$listing" == *$'remote\tfix/bug\t[remote] upstream/fix/bug\tupstream'* ]]
[[ "$listing" != *origin/HEAD* && "$listing" != *'[remote] origin/main'* ]]

export TEST_SELECT_TYPE=remote TEST_SELECT_VALUE=feature/login TEST_SELECT_REMOTE=origin
"$branches" "$project"
worktree="$TEST_WORKTREE_ROOT/project one--feature-login"
[[ $(cat "$TEST_OPENED") == "$worktree" ]]
[[ $(git -C "$worktree" branch --show-current) == feature/login ]]
[[ $(git -C "$worktree" rev-parse HEAD) == "$remote_commit" ]]
[[ $(git -C "$worktree" rev-parse --symbolic-full-name '@{upstream}') == refs/remotes/origin/feature/login ]]
[[ $(git -C "$project" branch --show-current) == main ]]
[[ $(git -C "$project" rev-parse HEAD) == "$base_commit" ]]
[[ $(cat "$project/file") == 'uncommitted main' ]]

# Remote branches become local entries, and existing worktrees retain changes.
listing=$("$branches" --list "$worktree")
[[ "$listing" == *$'local\tfeature/login\t[local] feature/login'* ]]
[[ "$listing" != *'[remote] origin/feature/login'* ]]
printf 'worktree changes\n' > "$worktree/file"
export TEST_SELECT_TYPE=local TEST_SELECT_VALUE=feature/login TEST_SELECT_REMOTE=''
"$branches" "$worktree"
[[ $(cat "$TEST_OPENED") == "$worktree" ]]
[[ $(cat "$worktree/file") == 'worktree changes' ]]

export TEST_SELECT_VALUE=main
"$branches" "$worktree"
[[ $(cat "$TEST_OPENED") == "$project" ]]
export TEST_SELECT_VALUE=local-task
"$branches" "$project"
[[ $(cat "$TEST_OPENED") == "$TEST_WORKTREE_ROOT/project one--local-task" ]]
[[ $(git -C "$TEST_WORKTREE_ROOT/project one--local-task" rev-parse HEAD) == "$base_commit" ]]

export TEST_SELECT_TYPE=remote TEST_SELECT_VALUE=fix/bug TEST_SELECT_REMOTE=upstream
"$branches" "$project"
[[ $(cat "$TEST_OPENED") == "$TEST_WORKTREE_ROOT/project one--fix-bug" ]]
[[ $(git -C "$TEST_WORKTREE_ROOT/project one--fix-bug" rev-parse --symbolic-full-name '@{upstream}') == refs/remotes/upstream/fix/bug ]]

# The directory picker contains only directories and opens the selected one.
listing=$("$projects" --list "$project")
[[ "$listing" == *"$project"* && "$listing" == *"$worktree"* ]]
[[ "$listing" != *'[local]'* && "$listing" != *'[remote]'* ]]
export TEST_SELECT_TYPE=project TEST_SELECT_VALUE="$project" TEST_SELECT_REMOTE=''
[[ $("$projects") == "$project" ]]
export TEST_SELECT_TYPE=worktree TEST_SELECT_VALUE="$worktree"
[[ $("$projects") == "$worktree" ]]

export TEST_CANCEL=true
previous_opened=$(cat "$TEST_OPENED")
"$branches" "$project"
[[ $(cat "$TEST_OPENED") == "$previous_opened" ]]
[[ -z $("$projects") ]]
unset TEST_CANCEL

if "$branches" "$test_directory" > /dev/null 2>&1; then
    printf 'FAIL: non-repo directory was accepted\n' >&2
    exit 1
fi
if tsp-wt --remote origin missing "$project" > /dev/null 2>&1; then
    printf 'FAIL: missing remote branch was accepted\n' >&2
    exit 1
fi
if tsp-wt --remote invalid feature/login "$project" > /dev/null 2>&1; then
    printf 'FAIL: unknown remote was accepted\n' >&2
    exit 1
fi
if tsp-wt 'bad branch' "$project" > /dev/null 2>&1; then
    printf 'FAIL: invalid branch was accepted\n' >&2
    exit 1
fi
if tsp-wt > /dev/null 2>&1; then
    printf 'FAIL: empty input was accepted\n' >&2
    exit 1
fi
git -C "$project" update-ref refs/remotes/upstream/local-task "$remote_commit"
if tsp-wt --remote upstream local-task "$project" > /dev/null 2>&1; then
    printf 'FAIL: conflicting local branch was accepted\n' >&2
    exit 1
fi

# Categorized repositories keep their complete parent structure, with or
# without a language folder. Creation from a linked worktree uses the main repo.
export HOME="$test_directory/home space"
mkdir -p "$HOME/code/work" "$HOME/code/personal"
printf '%s\n' '~/code/work/*' '~/code/personal/*' "$TEST_WORKTREE_ROOT" > "$TMUX_SESSION_DIRS_CONFIG"
for category in work/python personal/shell work personal; do
    grouped_project="$HOME/code/$category/grouped repo"
    grouped_root="$HOME/code/$category/worktrees"
    git clone -q "$project" "$grouped_project"
    tsp-wt feature/grouped "$grouped_project"
    grouped_worktree="$grouped_root/grouped repo--feature-grouped"
    [[ $(cat "$TEST_OPENED") == "$grouped_worktree" ]]
    tsp-wt second-task "$grouped_worktree"
    [[ $(cat "$TEST_OPENED") == "$grouped_root/grouped repo--second-task" ]]
    listing=$("$projects" --list)
    [[ "$listing" == *$'project\t'"$grouped_project"$'\t'* ]]
    [[ "$listing" == *$'worktree\t'"$grouped_worktree"$'\t'* ]]

    # Existing worktrees at the old location retain their files and path.
    legacy_worktree="$TEST_WORKTREE_ROOT/legacy-${category//\//-}"
    git -C "$grouped_project" worktree add -q -b legacy-task "$legacy_worktree"
    printf 'local changes\n' > "$legacy_worktree/file"
    tsp-wt legacy-task "$grouped_project"
    [[ $(cat "$TEST_OPENED") == "$legacy_worktree" ]]
    [[ $(cat "$legacy_worktree/file") == 'local changes' ]]

    # The removal binding accepts grouped worktrees and protects local files.
    remover="$repo_root/bin/tsp-worktree-remove"
    if "$remover" --path "$grouped_project" > /dev/null 2>&1; then
        printf 'FAIL: removal accepted the main repository\n' >&2
        exit 1
    fi
    printf 'local changes\n' > "$grouped_worktree/file"
    if "$remover" --path "$grouped_worktree" > /dev/null 2>&1; then
        printf 'FAIL: removal accepted a dirty worktree\n' >&2
        exit 1
    fi
    [[ -d "$grouped_worktree" ]]
    git -C "$grouped_worktree" restore file
    "$remover" --path "$grouped_worktree" > /dev/null 2>&1
    [[ ! -e "$grouped_worktree" ]]
    external_worktree="$test_directory/external-${category//\//-}"
    git -C "$grouped_project" worktree add -q -b external-task "$external_worktree"
    if "$remover" --path "$external_worktree" > /dev/null 2>&1; then
        printf 'FAIL: removal accepted an unmanaged worktree\n' >&2
        exit 1
    fi
    [[ -d "$external_worktree" ]]
done

printf 'PASS: separate pickers, remote tracking, grouped and legacy worktrees, main isolation, cancellation, and invalid input\n'
