# Prefer the current worktree's Linux venv, then the original checkout's venv.
() {
    local project_root=$PWD venv_directory
    project_root=$(git rev-parse --show-toplevel 2>/dev/null) || project_root=$PWD

    for venv_directory in "$project_root/.venv" "${PROJECTRC_PROJECT_DIRECTORY:-$project_root}/.venv"; do
        if [[ -r "$venv_directory/bin/activate" && -x "$venv_directory/bin/python" ]]; then
            source "$venv_directory/bin/activate"
            return
        fi
    done
}
