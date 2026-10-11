#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT

test_home="$test_directory/home space"
export TEST_WORKTREE_ROOT="$test_home/code/worktrees"
subject="$test_directory/tsp-pr"
sed 's|$HOME/code/worktrees|$TEST_WORKTREE_ROOT|g' "$repo_root/bin/tsp-pr" > "$subject"
chmod +x "$subject"
export TEST_REAL_GIT
TEST_REAL_GIT=$(command -v git)
export TEST_REMOTE="$test_directory/remote.git"
export TEST_OPENED="$test_directory/opened"
export TEST_CHECKOUT_LOG="$test_directory/checkouts"
export TEST_HEAD_REMOTE=https://github.com/contributor/project.git
mkdir -p "$test_home/projects/project one" "$test_directory/bin"
project="$test_home/projects/project one"
config="$test_directory/dirs"
printf '%s\n' "$test_home/projects" "$TEST_WORKTREE_ROOT" > "$config"

cat > "$test_directory/bin/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == -C && ${3:-} == fetch ]]; then
    exec "$TEST_REAL_GIT" -C "$2" fetch "$TEST_REMOTE" "${@:5}"
fi
exec "$TEST_REAL_GIT" "$@"
SH
cat > "$test_directory/bin/tmux" <<'SH'
#!/usr/bin/env bash
exit 1
SH
cat > "$test_directory/bin/tsp" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$1" > "$TEST_OPENED"
SH
cat > "$test_directory/bin/gh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ $# == 9 && $1 == pr && $2 == checkout && $4 == --repo && $5 == example/project &&
    $6 == --branch && $8 == --worktree ]]
printf '%s\n' "$7" >> "$TEST_CHECKOUT_LOG"
[[ ${TEST_CHECKOUT_FAIL:-false} == false ]] || exit 1
branch=$7
worktree=$9
if [[ -e "$worktree" ]]; then
    "$TEST_REAL_GIT" -C "$worktree" fetch "$TEST_REMOTE" "refs/pull/$3/head"
    "$TEST_REAL_GIT" -C "$worktree" merge --ff-only FETCH_HEAD
else
    "$TEST_REAL_GIT" fetch "$TEST_REMOTE" "refs/pull/$3/head:$branch"
    "$TEST_REAL_GIT" worktree add -- "$worktree" "$branch"
fi
if ! "$TEST_REAL_GIT" config "branch.$branch.merge" > /dev/null; then
    "$TEST_REAL_GIT" config "branch.$branch.remote" "$TEST_HEAD_REMOTE"
    "$TEST_REAL_GIT" config "branch.$branch.pushRemote" "$TEST_HEAD_REMOTE"
    "$TEST_REAL_GIT" config "branch.$branch.merge" "refs/heads/$branch"
fi
SH
chmod +x "$test_directory/bin/"*
export PATH="$test_directory/bin:$PATH"

git init -q --bare "$TEST_REMOTE"
git -C "$project" init -q -b main
git -C "$project" config user.name Test
git -C "$project" config user.email test@example.com
printf 'base\n' > "$project/file"
git -C "$project" add file
git -C "$project" commit -qm base
base_commit=$(git -C "$project" rev-parse HEAD)
git -C "$project" switch -qc fork-feature
printf 'PR\n' > "$project/file"
git -C "$project" commit -qam PR
pr_commit=$(git -C "$project" rev-parse HEAD)
git -C "$project" push -q "$TEST_REMOTE" HEAD:refs/pull/42/head
git -C "$project" switch -q main
git -C "$project" remote add origin https://github.com/example/project.git
printf 'local changes\n' > "$project/file"

"$subject" --config "$config" example/project 42 main fork-feature
worktree="$TEST_WORKTREE_ROOT/project one--pr-42"
[[ $(cat "$TEST_OPENED") == "$worktree" ]]
[[ $(git -C "$worktree" rev-parse HEAD) == "$pr_commit" ]]
[[ $(git -C "$worktree" branch --show-current) == fork-feature ]]
[[ $(git -C "$worktree" config branch.fork-feature.remote) == "$TEST_HEAD_REMOTE" ]]
[[ $(git -C "$worktree" config branch.fork-feature.merge) == refs/heads/fork-feature ]]
[[ $(git -C "$worktree" config branch.fork-feature.pushRemote) == "$TEST_HEAD_REMOTE" ]]
[[ $(cat "$TEST_CHECKOUT_LOG") == fork-feature ]]
[[ $(git -C "$project" rev-parse HEAD) == "$base_commit" ]]
[[ $(git -C "$project" branch --show-current) == main ]]
[[ $(cat "$project/file") == 'local changes' ]]

printf 'review changes\n' > "$worktree/file"
(cd "$worktree" && "$subject" --config "$config" example/project 42 main fork-feature)
[[ $(cat "$worktree/file") == 'review changes' ]]
[[ $(cat "$TEST_CHECKOUT_LOG") == fork-feature ]]
[[ $("$subject" --config "$config" --resolve-only example/project 42 main fork-feature) == "$project" ]]

# Reuse any worktree that already has the source branch, including the main one.
"$subject" --config "$config" example/project 43 main main
[[ $(cat "$TEST_OPENED") == "$project" ]]
[[ $(cat "$project/file") == 'local changes' ]]
[[ $(cat "$TEST_CHECKOUT_LOG") == fork-feature ]]
other_worktree="$test_home/other worktree"
git -C "$project" worktree move "$worktree" "$other_worktree"
"$subject" --config "$config" example/project 42 main fork-feature
[[ $(cat "$TEST_OPENED") == "$other_worktree" ]]
[[ $(cat "$other_worktree/file") == 'review changes' ]]
git -C "$project" worktree move "$other_worktree" "$worktree"

# Migrate a legacy branch while preserving local commits and uncommitted changes.
git -C "$worktree" commit -qam 'local review commit'
local_commit=$(git -C "$worktree" rev-parse HEAD)
printf 'more review changes\n' > "$worktree/file"
git -C "$worktree" branch -m pr-42
git -C "$worktree" config --remove-section branch.pr-42
export TEST_CHECKOUT_FAIL=true
if "$subject" --config "$config" example/project 42 main fork-feature > /dev/null 2>&1; then
    printf 'FAIL: legacy migration ignored checkout failure\n' >&2
    exit 1
fi
[[ $(git -C "$worktree" branch --show-current) == pr-42 ]]
[[ $(git -C "$worktree" rev-parse HEAD) == "$local_commit" ]]
[[ $(cat "$worktree/file") == 'more review changes' ]]
unset TEST_CHECKOUT_FAIL
"$subject" --config "$config" example/project 42 main fork-feature
[[ $(git -C "$worktree" branch --show-current) == fork-feature ]]
[[ $(git -C "$worktree" rev-parse HEAD) == "$local_commit" ]]
[[ $(cat "$worktree/file") == 'more review changes' ]]
[[ $(git -C "$worktree" config branch.fork-feature.remote) == "$TEST_HEAD_REMOTE" ]]
[[ $(git -C "$worktree" config branch.fork-feature.merge) == refs/heads/fork-feature ]]

# A new source branch gets its own worktree and source tracking configuration.
git -C "$project" push -q "$TEST_REMOTE" "$pr_commit:refs/pull/44/head"
export TEST_HEAD_REMOTE=origin
"$subject" --config "$config" example/project 44 main feature/new
new_worktree="$TEST_WORKTREE_ROOT/project one--pr-44"
[[ $(cat "$TEST_OPENED") == "$new_worktree" ]]
[[ $(git -C "$new_worktree" branch --show-current) == feature/new ]]
[[ $(git -C "$new_worktree" rev-parse HEAD) == "$pr_commit" ]]
[[ $(git -C "$new_worktree" config branch.feature/new.remote) == origin ]]

export TEST_CHECKOUT_FAIL=true
if "$subject" --config "$config" example/project 45 main feature/failure > /dev/null 2>&1; then
    printf 'FAIL: checkout failure was ignored\n' >&2
    exit 1
fi
[[ $(cat "$TEST_OPENED") == "$new_worktree" ]]
unset TEST_CHECKOUT_FAIL

if "$subject" --config "$config" example/project invalid main fork-feature > /dev/null 2>&1; then
    printf 'FAIL: invalid PR number was accepted\n' >&2
    exit 1
fi
if "$subject" > /dev/null 2>&1; then
    printf 'FAIL: empty input was accepted\n' >&2
    exit 1
fi
if "$subject" --config "$config" example/project 42 main 'bad branch' > /dev/null 2>&1; then
    printf 'FAIL: invalid source branch was accepted\n' >&2
    exit 1
fi
git -C "$project" worktree remove --force "$worktree"
mkdir -p "$worktree"
if "$subject" --config "$config" example/project 42 main fork-feature > /dev/null 2>&1; then
    printf 'FAIL: occupied destination was accepted\n' >&2
    exit 1
fi

# PR worktrees use the same category and optional language as branch worktrees.
export HOME="$test_home"
for category in work/python personal/shell work personal; do
    grouped_project="$HOME/code/$category/grouped repo"
    git clone -q "$project" "$grouped_project"
    git -C "$grouped_project" remote set-url origin https://github.com/example/project.git
    printf '%s\n' "$(dirname "$grouped_project")" > "$config"
    (cd "$grouped_project" && "$subject" --config "$config" example/project 44 main feature/grouped)
    grouped_worktree="$HOME/code/$category/worktrees/grouped repo--pr-44"
    [[ $(cat "$TEST_OPENED") == "$grouped_worktree" ]]
    [[ $(git -C "$grouped_worktree" branch --show-current) == feature/grouped ]]
    (cd "$grouped_project" && "$subject" --config "$config" example/project 44 main feature/grouped)
    [[ $(cat "$TEST_OPENED") == "$grouped_worktree" ]]
done

printf 'PASS: source branches, tracking, grouped worktrees, worktree reuse, legacy migration, isolation, and invalid input\n'
