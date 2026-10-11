#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../bin" && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME='Git Update Test' GIT_AUTHOR_EMAIL='test@example.invalid'
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    cat "$test_root/output" >&2
    exit 1
}

setup_case() {
    case_dir=$(mktemp -d "$test_root/case.XXXXXX")
    git init --bare --quiet "$case_dir/remote.git"
    git init --quiet --initial-branch=main "$case_dir/seed"
    git -C "$case_dir/seed" commit --quiet --allow-empty -m initial
    git -C "$case_dir/seed" remote add origin "$case_dir/remote.git"
    git -C "$case_dir/seed" push --quiet --set-upstream origin main
    git --git-dir="$case_dir/remote.git" symbolic-ref HEAD refs/heads/main
    git clone --quiet "$case_dir/remote.git" "$case_dir/work with spaces"
    cd "$case_dir/work with spaces"
    : > "$test_root/output"
}

run_command() {
    "$script_dir/$@" > "$test_root/output" 2>&1
}

assert_branch() {
    git show-ref --verify --quiet "refs/heads/$1" || fail "branch was deleted: $1"
}

assert_deleted() {
    if git show-ref --verify --quiet "refs/heads/$1"; then
        fail "branch was not deleted: $1"
    fi
}

stale_branch() {
    git branch "$1" main
    git push --quiet origin "$1"
    git branch --set-upstream-to="origin/$1" "$1" >/dev/null
    git -C "$case_dir/seed" push --quiet origin --delete "$1"
}

# Only the current branch advances. An unpublished branch and a renamed local
# branch with an existing upstream survive, even with an affirmative answer.
setup_case
git switch --quiet -c unpublished
git commit --quiet --allow-empty -m unpublished
git switch --quiet main
git branch local-main main
git branch --set-upstream-to=origin/main local-main >/dev/null
old_main=$(git rev-parse main)
git -C "$case_dir/seed" commit --quiet --allow-empty -m remote-update
git -C "$case_dir/seed" push --quiet origin main
run_command git-update <<< y || fail 'normal update failed'
[[ $(git rev-parse main) == "$(git -C "$case_dir/seed" rev-parse main)" ]] || fail 'main did not advance'
[[ $(git rev-parse local-main) == "$old_main" ]] || fail 'another local branch advanced'
assert_branch unpublished
[[ $(git branch --show-current) == main ]] || fail 'current branch changed'

# A merged branch with a missing upstream is deleted without confirmation.
setup_case
stale_branch stale
run_command git-update </dev/null || fail 'automatic safe deletion failed'
assert_deleted stale
if rg -q "Delete branch 'stale'" "$test_root/output"; then fail 'safe deletion required confirmation'; fi

# Unique commits require a separate force confirmation.
setup_case
stale_branch unique
git switch --quiet unique
git commit --quiet --allow-empty -m unique-local-work
git switch --quiet main
run_command git-update <<< '' || fail 'empty response failed'
assert_branch unique
run_command git-update </dev/null || fail 'EOF response failed'
assert_branch unique
run_command git-update <<< n || fail 'rejection failed'
assert_branch unique
run_command git-update <<< y || fail 'missing force confirmation failed'
assert_branch unique
rg -q 'Force-delete' "$test_root/output" || fail 'force confirmation was not shown'
run_command git-update <<< $'y\nn' || fail 'force rejection failed'
assert_branch unique
run_command git-update <<< $'y\ny' || fail 'confirmed force deletion failed'
assert_deleted unique

# A branch with a differently named, missing upstream is still a candidate.
setup_case
stale_branch old-name
git branch -m old-name renamed
run_command git-del-local <<< y || fail 'renamed upstream cleanup failed'
assert_deleted renamed

# Current branches and locked worktrees are preserved.
setup_case
stale_branch other-worktree
git worktree add --quiet "$case_dir/other worktree" other-worktree
git worktree lock "$case_dir/other worktree"
run_command git-update <<< y || fail 'worktree branch interrupted update'
assert_branch other-worktree
if rg -q 'Cleanup candidate: other-worktree' "$test_root/output"; then fail 'worktree branch was a candidate'; fi
stale_branch current-stale
git switch --quiet current-stale
run_command git-del-local <<< y || fail 'current branch interrupted cleanup'
assert_branch current-stale

# A clean, merged worktree with a gone upstream and its branch are removed.
setup_case
stale_branch merged-worktree
git worktree add --quiet "$case_dir/clean worktree" merged-worktree
run_command git-update </dev/null || fail 'automatic worktree cleanup failed'
[[ ! -e $case_dir/clean\ worktree ]] || fail 'clean worktree was not removed'
assert_deleted merged-worktree
if rg -q '\[y/N\]' "$test_root/output"; then fail 'safe worktree cleanup required confirmation'; fi

# Unusual branch names and newline paths remain separate fields. A tag with
# the same name must not confuse branch selection.
setup_case
stale_branch 'merged|branch'
worktree="$case_dir/"$'worktree\nwith newline'
git worktree add --quiet "$worktree" 'merged|branch'
git tag 'merged|branch' main
run_command git-update </dev/null || fail 'unusual names interrupted cleanup'
[[ ! -e $worktree ]] || fail 'worktree with newline was not removed'
assert_deleted 'merged|branch'
git show-ref --verify --quiet 'refs/tags/merged|branch' || fail 'tag was deleted during branch cleanup'

# Changed, staged, untracked, and ignored files prevent worktree removal.
for dirty_kind in changed staged untracked ignored; do
    setup_case
    printf 'tracked\n' > tracked.txt
    git add tracked.txt
    git commit --quiet -m tracked-file
    git push --quiet origin main
    stale_branch dirty-worktree
    worktree="$case_dir/dirty worktree"
    git worktree add --quiet "$worktree" dirty-worktree
    case "$dirty_kind" in
        changed) printf 'changed\n' > "$worktree/tracked.txt" ;;
        staged)
            printf 'changed\n' > "$worktree/tracked.txt"
            git -C "$worktree" add tracked.txt
            ;;
        untracked) printf 'local\n' > "$worktree/local.txt" ;;
        ignored)
            printf 'local.env\n' >> "$(git rev-parse --git-path info/exclude)"
            printf 'local\n' > "$worktree/local.env"
            ;;
    esac
    run_command git-update </dev/null || fail "dirty worktree cleanup failed: $dirty_kind"
    [[ -d $worktree ]] || fail "dirty worktree was removed: $dirty_kind"
    assert_branch dirty-worktree
done

# Detached worktrees and branches without an upstream remain untouched.
setup_case
git worktree add --quiet --detach "$case_dir/detached worktree" main
git worktree add --quiet -b unpublished-worktree "$case_dir/unpublished worktree" main
run_command git-update </dev/null || fail 'protected worktree cleanup failed'
[[ -d $case_dir/detached\ worktree && -d $case_dir/unpublished\ worktree ]] || fail 'protected worktree was removed'
assert_branch unpublished-worktree

# An existing upstream and submodules prevent automatic worktree removal.
setup_case
git branch live-worktree main
git branch --set-upstream-to=origin/main live-worktree >/dev/null
git worktree add --quiet "$case_dir/live worktree" live-worktree
printf '[submodule "example"]\n\tpath = example\n\turl = example.invalid\n' > .gitmodules
git add .gitmodules
git commit --quiet -m submodule-config
git push --quiet origin main
stale_branch submodule-worktree
git worktree add --quiet "$case_dir/submodule worktree" submodule-worktree
run_command git-update </dev/null || fail 'live or submodule worktree cleanup failed'
[[ -d $case_dir/live\ worktree && -d $case_dir/submodule\ worktree ]] || fail 'live or submodule worktree was removed'
assert_branch live-worktree
assert_branch submodule-worktree

# Commits outside the current branch require approval to remove the worktree.
setup_case
stale_branch unique-worktree
worktree="$case_dir/unique worktree"
git worktree add --quiet "$worktree" unique-worktree
git -C "$worktree" commit --quiet --allow-empty -m unique-worktree-commit
run_command git-update </dev/null || fail 'unique worktree review failed'
[[ -d $worktree ]] || fail 'unique worktree was removed without approval'
assert_branch unique-worktree
run_command git-update <<< $'y\nn' || fail 'approved worktree removal failed'
[[ ! -e $worktree ]] || fail 'approved worktree was not removed'
assert_branch unique-worktree

# Running from a linked worktree preserves both the current and main worktrees.
setup_case
stale_branch current-linked
worktree="$case_dir/current linked worktree"
git worktree add --quiet "$worktree" current-linked
cd "$worktree"
run_command git-del-local </dev/null || fail 'cleanup from linked worktree failed'
[[ -d $worktree && -d $case_dir/work\ with\ spaces ]] || fail 'current or main worktree was removed'
assert_branch current-linked

# Missing metadata respects expiration and locking. Expired, reachable metadata
# is pruned, while a missing detached worktree with unique commits is preserved.
setup_case
git worktree add --quiet -b missing "$case_dir/missing worktree" main
metadata=$(git -C "$case_dir/missing worktree" rev-parse --absolute-git-dir)
rm -rf "$case_dir/missing worktree"
run_command git-update </dev/null || fail 'fresh missing metadata cleanup failed'
[[ -d $metadata ]] || fail 'fresh metadata was pruned'
touch -d '1 year ago' "$metadata/gitdir" "$metadata/index"
run_command git-update </dev/null || fail 'expired metadata cleanup failed'
[[ ! -e $metadata ]] || fail 'expired metadata was not pruned'
assert_branch missing

git worktree add --quiet --detach "$case_dir/missing detached" main
git -C "$case_dir/missing detached" commit --quiet --allow-empty -m unique-detached-commit
metadata=$(git -C "$case_dir/missing detached" rev-parse --absolute-git-dir)
rm -rf "$case_dir/missing detached"
touch -d '1 year ago' "$metadata/gitdir" "$metadata/index"
run_command git-update </dev/null || fail 'unique missing metadata cleanup failed'
[[ -d $metadata ]] || fail 'unique detached metadata was pruned'

setup_case
git worktree add --quiet -b missing-locked "$case_dir/missing locked" main
git worktree lock "$case_dir/missing locked"
metadata=$(git -C "$case_dir/missing locked" rev-parse --absolute-git-dir)
rm -rf "$case_dir/missing locked"
touch -d '1 year ago' "$metadata/gitdir" "$metadata/index"
run_command git-update </dev/null || fail 'locked missing metadata cleanup failed'
[[ -d $metadata ]] || fail 'locked metadata was pruned'

# Tmux sessions and panes protect an otherwise disposable worktree. Stub only
# tmux so the integration test never changes the user's tmux server.
setup_case
stale_branch tmux-worktree
worktree="$case_dir/tmux worktree"
git worktree add --quiet "$worktree" tmux-worktree
mkdir -p "$case_dir/fake-bin" "$worktree/subdirectory"
cat > "$case_dir/fake-bin/tmux" <<'SH'
#!/usr/bin/env bash
case "$1" in
    list-sessions) [[ $TEST_TMUX_KIND == session ]] && printf '$1\n' ;;
    list-panes) [[ $TEST_TMUX_KIND == pane ]] && printf '%%1\n' ;;
    display-message) printf '%s\n' "$TEST_TMUX_PATH" ;;
esac
exit 0
SH
chmod +x "$case_dir/fake-bin/tmux"
saved_path=$PATH
export PATH="$case_dir/fake-bin:$PATH" TEST_TMUX_PATH="$worktree/subdirectory"
for kind in session pane; do
    export TEST_TMUX_KIND=$kind
    run_command git-update </dev/null || fail "tmux protection failed: $kind"
    [[ -d $worktree ]] || fail "active tmux worktree was removed: $kind"
    assert_branch tmux-worktree
done
export PATH=$saved_path
unset TEST_TMUX_PATH TEST_TMUX_KIND

# Default remote follows the current upstream. Explicit cleanup isolates remotes.
setup_case
stale_branch origin-stale
git init --bare --quiet "$case_dir/second.git"
git remote add second "$case_dir/second.git"
git push --quiet second main
git branch second-stale main
git push --quiet second second-stale
git branch --set-upstream-to=second/second-stale second-stale >/dev/null
git --git-dir="$case_dir/second.git" update-ref -d refs/heads/second-stale
run_command git-del-local second <<< y || fail 'explicit remote cleanup failed'
assert_deleted second-stale
assert_branch origin-stale
git show-ref --verify --quiet refs/remotes/origin/origin-stale || fail 'wrong remote was pruned'
run_command git-update <<< y || fail 'default upstream remote was not selected'
assert_deleted origin-stale

# With no upstream and multiple remotes, explicit selection is required.
git switch --quiet -c no-upstream
if run_command git-del-local </dev/null; then fail 'ambiguous remote was accepted'; fi
run_command git-del-local origin </dev/null || fail 'explicit cleanup on unpublished branch failed'
assert_branch no-upstream
if run_command git-update origin </dev/null; then fail 'update without upstream was accepted'; fi

# A divergent branch stops before cleanup, even when pull.rebase is configured.
setup_case
stale_branch stale
git commit --quiet --allow-empty -m local-divergence
local_tip=$(git rev-parse HEAD)
git -C "$case_dir/seed" commit --quiet --allow-empty -m remote-divergence
git -C "$case_dir/seed" push --quiet origin main
git config pull.rebase true
if run_command git-update <<< y; then fail 'divergent update reported success'; fi
assert_branch stale
[[ $(git rev-parse HEAD) == "$local_tip" ]] || fail 'divergent local branch changed'
if rg -q 'Cleanup candidate:' "$test_root/output"; then fail 'cleanup ran after pull failure'; fi

# A fetch failure stops before cleanup.
setup_case
stale_branch stale
git remote set-url origin "$case_dir/nonexistent.git"
if run_command git-update <<< y; then fail 'fetch failure reported success'; fi
assert_branch stale
if rg -q 'Cleanup candidate:' "$test_root/output"; then fail 'cleanup ran after fetch failure'; fi

# Local edits survive a blocked update, even with automatic stashing configured.
setup_case
printf 'initial\n' > shared.txt
git add shared.txt
git commit --quiet -m tracked-file
git push --quiet origin main
git -C "$case_dir/seed" pull --quiet --ff-only
printf 'local edit\n' > shared.txt
printf 'remote edit\n' > "$case_dir/seed/shared.txt"
git -C "$case_dir/seed" add shared.txt
git -C "$case_dir/seed" commit --quiet -m remote-edit
git -C "$case_dir/seed" push --quiet origin main
git config merge.autostash true
git config rebase.autostash true
if run_command git-update </dev/null; then fail 'update overwrote local edits'; fi
[[ $(cat shared.txt) == 'local edit' ]] || fail 'local edits changed'
[[ -z $(git stash list) ]] || fail 'local edits were stashed'

# The update-only alias never offers deletion.
setup_case
stale_branch stale
git worktree add --quiet "$case_dir/update-only worktree" stale
run_command git-pull-local <<< y || fail 'update-only alias failed'
assert_branch stale
[[ -d $case_dir/update-only\ worktree ]] || fail 'update-only alias removed a worktree'
if rg -q 'Cleanup candidate:' "$test_root/output"; then fail 'update-only alias offered deletion'; fi
git worktree remove "$case_dir/update-only worktree"

# Quiet mode keeps the candidate and confirmation visible. An explicit remote
# that differs from the current upstream fails before fetching that remote.
git switch --quiet stale
git commit --quiet --allow-empty -m unique-local-work
git switch --quiet main
run_command git-update --quiet <<< n || fail 'quiet update failed'
rg -q 'Cleanup candidate: stale' "$test_root/output" || fail 'quiet mode hid candidates'
rg -q "Delete branch 'stale'" "$test_root/output" || fail 'quiet mode hid confirmation'
git init --bare --quiet "$case_dir/other.git"
git remote add other "$case_dir/other.git"
if run_command git-update other </dev/null; then fail 'mismatched update remote was accepted'; fi
assert_branch stale

# Invalid input fails before any fetch or deletion.
setup_case
stale_branch stale
for args in '-y' '--yes' '--invalid' 'missing' 'origin extra'; do
    read -r -a argument_list <<< "$args"
    if run_command git-del-local "${argument_list[@]}" <<< y; then fail "invalid input accepted: $args"; fi
    git show-ref --verify --quiet refs/remotes/origin/stale || fail 'invalid input caused a fetch'
    assert_branch stale
done

# Detached HEAD cannot update, but explicit cleanup remains available.
git switch --quiet --detach
if run_command git-update origin </dev/null; then fail 'detached update was accepted'; fi
run_command git-del-local origin <<< y || fail 'detached cleanup failed'
assert_deleted stale

# Bare and non-repository directories are rejected. Help needs no repository.
cd "$test_root"
if run_command git-update </dev/null; then fail 'non-repository was accepted'; fi
run_command git-update --help || fail 'help outside repository failed'
cd "$case_dir/remote.git"
if run_command git-del-local </dev/null; then fail 'bare repository was accepted'; fi

printf 'PASS: git-update integration tests\n'
