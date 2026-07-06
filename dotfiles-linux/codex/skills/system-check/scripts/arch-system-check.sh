#!/usr/bin/env bash
set -uo pipefail

section() {
    printf '\n== %s ==\n' "$1"
}

status() {
    printf '%-8s %s\n' "$1" "$2"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

run_limited() {
    local limit="$1"
    shift
    "$@" 2>&1 | sed -n "1,${limit}p"
}

section "System"
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    status "INFO" "OS: ${PRETTY_NAME:-unknown}"
else
    status "CHECK" "/etc/os-release is missing"
fi
status "INFO" "Kernel: $(uname -r)"
status "INFO" "Uptime: $(uptime -p 2>/dev/null || uptime)"

section "Privilege"
if [[ "${SYSTEM_CHECK_SKIP_SUDO:-0}" == "1" ]]; then
    status "INFO" "Sudo probe skipped by SYSTEM_CHECK_SKIP_SUDO=1"
    can_sudo=0
elif have sudo && sudo -n true 2>/dev/null; then
    status "OK" "Non-interactive sudo is available"
    can_sudo=1
else
    status "CHECK" "Non-interactive sudo is unavailable; privileged checks are skipped"
    can_sudo=0
fi

section "Pacman State"
if [[ -e /var/lib/pacman/db.lck ]]; then
    status "CRITICAL" "Pacman database lock exists: /var/lib/pacman/db.lck"
else
    status "OK" "No pacman database lock"
fi

if have checkupdates; then
    updates="$(checkupdates 2>/dev/null || true)"
    if [[ -n "$updates" ]]; then
        count="$(printf '%s\n' "$updates" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count repo package updates available"
        printf '%s\n' "$updates" | sed -n '1,30p'
        if (( count > 30 )); then
            status "INFO" "Update list truncated at 30 packages"
        fi
    else
        status "OK" "No repo package updates reported by checkupdates"
    fi
elif have pacman; then
    updates="$(pacman -Qu 2>/dev/null || true)"
    if [[ -n "$updates" ]]; then
        count="$(printf '%s\n' "$updates" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count package updates available according to pacman -Qu"
        printf '%s\n' "$updates" | sed -n '1,30p'
    else
        status "OK" "No package updates reported by pacman -Qu"
    fi
else
    status "CRITICAL" "pacman is not available"
fi

if have pacman; then
    orphans="$(pacman -Qtdq 2>/dev/null || true)"
    if [[ -n "$orphans" ]]; then
        count="$(printf '%s\n' "$orphans" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count orphaned packages"
        printf '%s\n' "$orphans" | sed -n '1,40p'
    else
        status "OK" "No orphaned packages"
    fi

    foreign="$(pacman -Qmq 2>/dev/null || true)"
    if [[ -n "$foreign" ]]; then
        count="$(printf '%s\n' "$foreign" | sed '/^$/d' | wc -l)"
        status "CHECK" "$count foreign/AUR packages installed"
        printf '%s\n' "$foreign" | sed -n '1,40p'
    else
        status "OK" "No foreign packages"
    fi
fi

section "AUR Helper"
if have yay; then
    status "INFO" "yay is available"
    aur_updates="$(yay -Qua 2>/dev/null || true)"
    if [[ -n "$aur_updates" ]]; then
        count="$(printf '%s\n' "$aur_updates" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count AUR updates available"
        printf '%s\n' "$aur_updates" | sed -n '1,30p'
    else
        status "OK" "No AUR updates reported by yay"
    fi
elif have paru; then
    status "INFO" "paru is available"
    aur_updates="$(paru -Qua 2>/dev/null || true)"
    if [[ -n "$aur_updates" ]]; then
        count="$(printf '%s\n' "$aur_updates" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count AUR updates available"
        printf '%s\n' "$aur_updates" | sed -n '1,30p'
    else
        status "OK" "No AUR updates reported by paru"
    fi
else
    status "CHECK" "No yay/paru AUR helper found"
fi

section "Config Merge Files"
if have pacdiff; then
    pacnew="$(find /etc -xdev \( -name '*.pacnew' -o -name '*.pacsave' \) -print 2>/dev/null | sort)"
    if [[ -n "$pacnew" ]]; then
        count="$(printf '%s\n' "$pacnew" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count pacnew/pacsave files need review"
        printf '%s\n' "$pacnew" | sed -n '1,50p'
    else
        status "OK" "No pacnew/pacsave files under /etc"
    fi
else
    status "CHECK" "pacdiff is not installed"
fi

section "Systemd"
failed_system="$(systemctl --failed --no-legend --plain 2>/dev/null || true)"
if [[ -n "$failed_system" ]]; then
    status "ACTION" "Failed system units"
    printf '%s\n' "$failed_system"
else
    status "OK" "No failed system units"
fi

failed_user="$(systemctl --user --failed --no-legend --plain 2>/dev/null || true)"
if [[ -n "$failed_user" ]]; then
    status "ACTION" "Failed user units"
    printf '%s\n' "$failed_user"
else
    status "OK" "No failed user units"
fi

section "Journal"
if have journalctl; then
    status "INFO" "Current boot priority 0..3 entries, truncated at 80 lines"
    journalctl -b -p 3 --no-pager 2>/dev/null | sed -n '1,80p' || true
else
    status "CHECK" "journalctl is unavailable"
fi

section "Filesystem"
df -h -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | awk 'NR == 1 {print; next} {gsub(/%/, "", $5); level=($5 >= 90 ? "CRITICAL" : ($5 >= 80 ? "ACTION" : "OK")); printf "%-8s %s %s %s %s %s\n", level, $1, $2, $3, $4, $6}'

section "Package Cache"
if [[ -d /var/cache/pacman/pkg ]]; then
    cache_size="$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')"
    status "INFO" "Pacman cache size: ${cache_size:-unknown}"
    if have paccache; then
        removable="$(paccache -d 2>/dev/null | awk '/finished:/ {print $2, $3, $4, $5, $6}' | tail -1)"
        [[ -n "$removable" ]] && status "CHECK" "paccache dry-run: $removable"
    else
        status "CHECK" "paccache is not installed"
    fi
else
    status "CHECK" "Pacman cache directory missing"
fi

section "Reboot Hint"
if have pacman; then
    installed_kernel="$(pacman -Q linux 2>/dev/null | awk '{print $2}' || true)"
    running_kernel="$(uname -r)"
    if [[ -n "$installed_kernel" && "$running_kernel" != *"${installed_kernel%%.*}"* ]]; then
        status "CHECK" "Running kernel ($running_kernel) may differ from installed linux package ($installed_kernel)"
    else
        status "OK" "No obvious linux package reboot mismatch"
    fi
fi

section "Timers"
systemctl list-timers --all --no-pager 2>/dev/null | sed -n '1,40p' || status "CHECK" "Unable to list system timers"

section "Flatpak"
if have flatpak; then
    flatpak_updates="$(flatpak remote-ls --updates 2>/dev/null || true)"
    if [[ -n "$flatpak_updates" ]]; then
        count="$(printf '%s\n' "$flatpak_updates" | sed '/^$/d' | wc -l)"
        status "ACTION" "$count Flatpak updates available"
        printf '%s\n' "$flatpak_updates" | sed -n '1,30p'
    else
        status "OK" "No Flatpak updates reported"
    fi
else
    status "INFO" "Flatpak is not installed"
fi

section "Suggested Next Steps"
status "INFO" "Review ACTION/CRITICAL/CHECK lines above before modifying the system"
if (( can_sudo == 0 )); then
    status "INFO" "Run privileged maintenance from an interactive terminal when needed"
fi
