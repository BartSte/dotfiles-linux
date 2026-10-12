#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
export PROJECTRC_LOADER="$repo_root/zsh/projectrc.zsh"
export PROJECTRC_HOME="$test_directory/config space"
export PROJECTRC_MAP="$PROJECTRC_HOME/mappings.conf"
export WH="$test_directory/windows user"
project="$test_directory/projects space/python/project one"
worktree="$test_directory/elsewhere/task worktree"
mkdir -p "$project/nested directory" "$PROJECTRC_HOME/projectrc.d" "$test_directory/elsewhere"
cp "$repo_root/zsh/projectrc/projectrc.d/python-work.zsh" "$PROJECTRC_HOME/projectrc.d/"
cp "$repo_root/zsh/projectrc/projectrc.d/python.zsh" "$PROJECTRC_HOME/projectrc.d/"
printf 'export SUBDIRECTORY_CONFIG=loaded\n' > "$PROJECTRC_HOME/projectrc.d/nested.zsh"
printf '%s\n' \
    "$test_directory/projects*/python/** python-work.zsh" \
    "$test_directory/projects*/python/** python.zsh" \
    "$test_directory/projects*/python/** python-work.zsh" \
    "$test_directory/projects*/python/**/nested* nested.zsh" > "$PROJECTRC_MAP"
git -C "$project" init -q -b main
git -C "$project" config user.name Test
git -C "$project" config user.email test@example.com
printf 'base\n' > "$project/nested directory/file"
git -C "$project" add .
git -C "$project" commit -qm base
git -C "$project" worktree add -q -b feature/task "$worktree"

load_config() {
    env -u WIN_VENV -u WIN_PY -u WSL_INTEROP WSL_DISTRO_NAME=fixture \
        zsh -ef -c '
            cd "$1"
            source "$PROJECTRC_LOADER"
            [[ "$PROJECTRC" == python-work ]]
            [[ "$WIN_VENV" == "$WH/venvs/project one" ]]
            [[ "$WIN_PY" == "$WIN_VENV/Scripts/python.exe" ]]
            [[ "$PWD" == "$1" ]]
            if [[ "$1" == */nested* ]]; then
                [[ "$SUBDIRECTORY_CONFIG" == loaded ]]
            fi
            print -r -- "$WIN_VENV"
        ' -- "$1"
}

original_venv=$(load_config "$project")
[[ $(load_config "$worktree") == "$original_venv" ]]
[[ $(load_config "$project/nested directory") == "$original_venv" ]]
[[ $(load_config "$worktree/nested directory") == "$original_venv" ]]

# Non-repository directories keep their existing path-based configuration.
plain_directory="$test_directory/projects space/python/plain directory"
mkdir -p "$plain_directory"
env -u WIN_VENV -u WIN_PY WSL_DISTRO_NAME=fixture zsh -ef -c '
    cd "$1"
    source "$PROJECTRC_LOADER"
    [[ "$WIN_VENV" == "$WH/venvs/plain directory" ]]
' -- "$plain_directory"

# Unmapped directories and non-WSL shells do not select a Windows venv.
env -u WIN_VENV -u WIN_PY WSL_DISTRO_NAME=fixture zsh -ef -c '
    cd "$1"
    source "$PROJECTRC_LOADER"
    [[ -z "$PROJECTRC" && -z ${WIN_VENV:-} && -z ${WIN_PY:-} ]]
' -- "$test_directory"
env -u WIN_VENV -u WIN_PY -u WSL_DISTRO_NAME -u WSL_INTEROP zsh -ef -c '
    cd "$1"
    source "$PROJECTRC_LOADER"
    [[ "$PROJECTRC" == python-work ]]
    [[ -z ${WIN_VENV:-} && -z ${WIN_PY:-} ]]
' -- "$worktree"

# A missing mapping file leaves the shell usable.
PROJECTRC_MAP="$test_directory/missing" zsh -ef -c '
    source "$PROJECTRC_LOADER"
    [[ -z "$PROJECTRC" ]]
'

# Real venvs exercise activation, interpreter selection, and child processes.
python3 -m venv --without-pip "$project/.venv"
load_linux_venv() {
    env -u VIRTUAL_ENV -u WSL_DISTRO_NAME -u WSL_INTEROP zsh -ef -c '
        cd "$1"
        source "$PROJECTRC_LOADER"
        [[ "$VIRTUAL_ENV" == "$2" ]]
        [[ "$(command -v python)" == "$2/bin/python" ]]
        [[ "$(python -c "import sys; print(sys.prefix)")" == "$2" ]]
        if command -v nvim >/dev/null; then
            nvim --headless -u NONE -i NONE "+lua assert(vim.env.VIRTUAL_ENV == vim.env.EXPECTED_VENV); assert(vim.fn.exepath(\"python\") == vim.env.EXPECTED_VENV .. \"/bin/python\")" +qa
        fi
    ' -- "$1" "$2"
}

export EXPECTED_VENV="$project/.venv"
load_linux_venv "$project" "$EXPECTED_VENV"
load_linux_venv "$project/nested directory" "$EXPECTED_VENV"
load_linux_venv "$worktree" "$EXPECTED_VENV"
load_linux_venv "$worktree/nested directory" "$EXPECTED_VENV"

python3 -m venv --without-pip "$worktree/.venv"
export EXPECTED_VENV="$worktree/.venv"
load_linux_venv "$worktree" "$EXPECTED_VENV"
load_linux_venv "$worktree/nested directory" "$EXPECTED_VENV"

# Missing Linux venvs leave the shell usable, including Windows-only venvs.
mkdir -p "$plain_directory/.venv/Scripts"
env -u VIRTUAL_ENV zsh -ef -c '
    cd "$1"
    source "$PROJECTRC_LOADER"
    [[ -z ${VIRTUAL_ENV:-} ]]
' -- "$plain_directory"

printf 'PASS: worktree configuration, Windows venv, Linux venv precedence, nested paths, spaces, and Neovim inheritance\n'
