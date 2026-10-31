#!/usr/bin/env bash
set -euo pipefail

wrapper=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../bin" && pwd)/gh
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export GIT_CONFIG_GLOBAL="$test_root/gitconfig" GIT_CONFIG_NOSYSTEM=1
unset GH_TOKEN GITHUB_TOKEN GH_HOST
mkdir -p "$test_root/bin" "$test_root/wrappers" "$test_root/personal" "$test_root/work"
ln -s "$wrapper" "$test_root/wrappers/gh"
export PATH="$test_root/wrappers:$test_root/bin:$PATH"
export GH_TEST_ROOT="$test_root"

cat > "$test_root/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == auth && ${2:-} == token ]]; then
    printf '%s\n' "${!#}" >> "$GH_TEST_ROOT/lookups"
    case "${!#}" in
        personal|work) printf 'fake-%s\n' "${!#}" ;;
        *) exit 1 ;;
    esac
else
    printf '%s' "${GH_TOKEN:-active}" > "$GH_TEST_ROOT/token"
    printf '%s\n' "$@" > "$GH_TEST_ROOT/arguments"
    [[ ${1:-} != fail ]] || exit 9
fi
MOCK
chmod +x "$test_root/bin/gh"
git config --file "$test_root/personal.config" gh.user personal
git config --file "$test_root/work.config" gh.user work
git config --file "$GIT_CONFIG_GLOBAL" "includeIf.gitdir:$test_root/personal/.path" "$test_root/personal.config"
git config --file "$GIT_CONFIG_GLOBAL" "includeIf.gitdir:$test_root/work/.path" "$test_root/work.config"
git init -q "$test_root/personal/repo with spaces"
git init -q "$test_root/work/repo"
mkdir "$test_root/personal/repo with spaces/subdir"

expect_token() {
    local expected=$1
    shift
    "$wrapper" "$@"
    [[ $(cat "$test_root/token") == "$expected" ]] || {
        printf 'FAIL: unexpected account\n' >&2
        exit 1
    }
}

cd "$test_root/personal/repo with spaces"
expect_token fake-personal api user --jq .login
cd subdir
expect_token fake-personal pr list --search 'title with spaces'
printf '%s\n' pr list --search 'title with spaces' > "$test_root/expected"
cmp "$test_root/expected" "$test_root/arguments"
cd "$test_root/work/repo"
expect_token fake-work api user
GH_TOKEN=override expect_token override api user
GITHUB_TOKEN=override expect_token active api user
GH_HOST=example.invalid expect_token active api user
expect_token active api user --hostname example.invalid
expect_token active api user --hostname=example.invalid
expect_token active auth status
expect_token active --version
cd "$test_root"
expect_token active api user
cd "$test_root/personal/repo with spaces"
git config gh.user unavailable
if "$wrapper" api user > "$test_root/output" 2>&1; then
    printf 'FAIL: missing credentials did not stop the command\n' >&2
    exit 1
fi
git config --unset gh.user
if "$wrapper" fail; then
    exit 1
else
    [[ $? == 9 ]]
fi

# Linked worktrees retain their repository's includeIf identity.
git -c user.name=Test -c user.email=test@example.invalid commit -q --allow-empty -m initial
git worktree add -q -b linked "$test_root/linked worktree"
cd "$test_root/linked worktree"
expect_token fake-personal api user

# Personal directories select an account before a repository exists.
(
    export HOME="$test_root/home"
    mkdir -p "$HOME/code/personal/new project" "$HOME/code/personal-other"
    git config --file "$HOME/.gitconfig-personal" gh.user personal
    cd "$HOME/code/personal"
    expect_token fake-personal api user
    cd 'new project'
    expect_token fake-personal repo clone owner/repo
    GH_TOKEN=override expect_token override api user
    expect_token active auth status
    git init -q
    git config gh.user work
    expect_token fake-work api user
    cd "$HOME/code/personal-other"
    expect_token active api user
    ln -s "$HOME/code/personal" "$HOME/personal-link"
    cd "$HOME/personal-link"
    expect_token fake-personal api user
)
printf 'PASS: account selection, subdirectories, worktrees, overrides, arguments, and failures\n'
