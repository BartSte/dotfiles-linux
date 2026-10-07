# Select the account for each CLI invocation, including after a directory change.
codex() {
    local project_directory=$PWD
    local personal_root="$HOME/code/personal"
    local selected_home="$HOME/.codex"
    local worktree_field
    local -a arguments=("$@")
    local argument_index=1

    # An explicit home takes precedence over automatic account selection.
    if [[ -n ${CODEX_HOME:-} ]]; then
        command codex "$@"
        return $?
    fi

    # Read directory overrides among the global CLI options.
    while (( argument_index <= ${#arguments} )); do
        case ${arguments[argument_index]} in
            -C|--cd)
                (( argument_index++ ))
                if (( argument_index <= ${#arguments} )); then
                    project_directory=${arguments[argument_index]}
                fi
                ;;
            --cd=*) project_directory=${arguments[argument_index]#--cd=} ;;
            -C?*) project_directory=${arguments[argument_index]#-C} ;;
            -c|--config|-m|--model|-p|--profile|-s|--sandbox|-a|--ask-for-approval|--enable|--disable|--remote|--remote-auth-token-env|--add-dir)
                (( argument_index++ ))
                ;;
            --|[^-]*) break ;;
        esac
        (( argument_index++ ))
    done
    project_directory=${project_directory:A}
    personal_root=${personal_root:A}

    # A linked worktree uses the account of its original checkout.
    if IFS= read -r -d '' worktree_field < <(git -C "$project_directory" worktree list --porcelain -z 2>/dev/null); then
        if [[ $worktree_field == 'worktree '* ]]; then
            project_directory=${worktree_field#worktree }
            project_directory=${project_directory:A}
        fi
    fi

    if [[ $project_directory == "$personal_root" || $project_directory == "$personal_root"/* ]]; then
        selected_home="$HOME/.codex-personal"
    fi
    CODEX_HOME="$selected_home" command codex "$@"
}
