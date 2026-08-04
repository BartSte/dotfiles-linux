CODEX_LUNA_MODEL="gpt-5.6-luna"

codex-commit() {
    if ! command -v codex >/dev/null 2>&1; then
        print -u2 -- "codex-commit: codex executable not found on PATH"
        return 127
    fi

    if ! command -v git >/dev/null 2>&1; then
        print -u2 -- "codex-commit: git executable not found on PATH"
        return 127
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print -u2 -- "codex-commit: current directory is not inside a Git repository"
        return 1
    fi

    local staged_status
    if git diff --cached --quiet --; then
        print -u2 -- "codex-commit: no staged changes"
        return 1
    else
        staged_status=$?
    fi

    if (( staged_status > 1 )); then
        print -u2 -- "codex-commit: could not inspect staged changes"
        return "$staged_status"
    fi

    codex exec \
        --ephemeral \
        --model "$CODEX_LUNA_MODEL" \
        --config model_reasoning_effort=low \
        '$commit Commit the complete set of currently staged changes using git. Split it into multiple focused commits when it contains independently reversible logical changes. Include every initially staged change, include no initially unstaged or untracked content, and do not push.'
    return $?
}
