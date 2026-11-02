#!/usr/bin/env bash
# Shared by the management command and the rbw pinentry helper.

initialize_windows_unlock() {
    local config identity helper_dir
    windows_powershell='/mnt/c/Program Files/PowerShell/7/pwsh.exe'
    if [[ ! -x $windows_powershell ]]; then
        windows_powershell='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
    fi
    [[ -x $windows_powershell ]] || { printf 'Windows PowerShell is unavailable.\n' >&2; return 1; }
    helper_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || return 1
    windows_script=$(wslpath -w "$helper_dir/windows-secret.ps1") || return 1
    config=$(rbw config show) || return 1
    identity=$(jq -cer --arg profile "${RBW_PROFILE:-}" \
        '[.email, .base_url, .identity_url, $profile] | select(.[0] != null and .[0] != "")' <<< "$config") || return 1
    secret_id=$(printf '%s' "$identity" | sha256sum)
    secret_id=${secret_id%% *}
    unlock_state=${XDG_STATE_HOME:-$HOME/.local/state}/rbw-windows-unlock/$secret_id
    mkdir -p -- "$unlock_state"
    chmod 700 "$unlock_state"
}

windows_secret() {
    "$windows_powershell" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$windows_script" \
        -Action "$1" -Id "$secret_id"
}

original_pinentry() {
    local executable=pinentry
    if [[ -f $unlock_state/pinentry ]]; then
        IFS= read -r executable < "$unlock_state/pinentry"
    fi
    [[ -n $executable && $executable != *rbw-pinentry-windows ]] || executable=pinentry
    "$executable" "$@"
}
