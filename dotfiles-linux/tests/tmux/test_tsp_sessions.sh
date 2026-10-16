#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
export TEST_SESSION_DIRECTORY="$test_directory/sessions"
export TEST_TMUX_LOG="$test_directory/tmux-log"
mkdir -p "$test_directory/bin" "$TEST_SESSION_DIRECTORY"

cat > "$test_directory/bin/tmux" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$TEST_TMUX_LOG"
case "$1" in
    has-session) [[ -f "$TEST_SESSION_DIRECTORY/${3#=}" ]] ;;
    display-message) cat "$TEST_SESSION_DIRECTORY/${4#=}" ;;
    new-session) printf '%s\n' "$6" > "$TEST_SESSION_DIRECTORY/$4" ;;
    list-windows) printf '%s\n' nvim shell codex ;;
esac
SH
chmod +x "$test_directory/bin/tmux"
export PATH="$test_directory/bin:$PATH"
export TMUX=test-client

# Two projects can open the same PR or branch without sharing a session.
for project_name in 'project one' 'project.two'; do
    project="$test_directory/projects/$project_name"
    mkdir -p "$project"
    git -C "$project" init -q -b main
    git -C "$project" -c user.name=Test -c user.email=test@example.com commit --allow-empty -qm base
    for branch in pr-123 feature-login; do
        worktree="$test_directory/worktrees/$project_name/$branch"
        git -C "$project" worktree add -q -b "$branch" "$worktree"
        session_name="${project_name//./_}--$branch"
        "$repo_root/bin/tsp" "$worktree"
        [[ $(cat "$TEST_SESSION_DIRECTORY/$session_name") == "$worktree" ]]
        [[ $(tail -n 1 "$TEST_TMUX_LOG") == "switch-client -t =$session_name" ]]

        # An existing session retains its path and does not run creation hooks again.
        "$repo_root/bin/tsp" "$worktree" --hook 'exit 99'
        [[ $(tail -n 1 "$TEST_TMUX_LOG") == "switch-client -t =$session_name" ]]

        # Outside tmux, attach to the existing session.
        TMUX= "$repo_root/bin/tsp" "$worktree"
        [[ $(tail -n 1 "$TEST_TMUX_LOG") == "attach-session -t =$session_name" ]]

        printf '%s\n' "$project" > "$TEST_SESSION_DIRECTORY/$session_name"
        if "$repo_root/bin/tsp" "$worktree" > /dev/null 2>&1; then
            printf 'FAIL: conflicting session path was accepted\n' >&2
            exit 1
        fi
    done
done

printf 'PASS: project-specific PR sessions, reuse, attach, and conflicting paths\n'
