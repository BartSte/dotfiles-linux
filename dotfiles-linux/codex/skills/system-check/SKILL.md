---
name: system-check
description: Audit and maintain an Arch Linux system. Use when Codex is asked to check whether the current Arch Linux machine is healthy, diagnose routine system maintenance issues, run periodic Arch upkeep, inspect failed services, package updates, pacnew files, orphaned packages, cache cleanup opportunities, reboot requirements, logs, filesystem pressure, AUR/Flatpak state, or recommend safe maintenance actions.
---

# System Check

## Overview

Use this skill to perform a pragmatic Arch Linux health and maintenance audit. Prefer read-only checks first, then propose or run modifying maintenance only when the user explicitly asks for fixes.

## Default Workflow

1. Confirm the host is Arch-based with `/etc/os-release`; if not Arch/Arch-like, state the mismatch and adapt cautiously.
2. Run the bundled audit script:

```bash
/home/barts/dotfiles-linux/codex/skills/system-check/scripts/arch-system-check.sh
```

3. Inspect the output and classify findings:
   - `CRITICAL`: likely broken or security-relevant now.
   - `ACTION`: should be fixed during maintenance.
   - `CHECK`: needs human judgment or optional follow-up.
   - `OK`: no action.
4. If the user asked to perform maintenance, apply fixes conservatively and verify after each category.
5. Finish with a concise report: what is healthy, what changed, what still needs attention, and any commands the user must run manually because they require interactive `sudo`.

## Safety Rules

- Do not run destructive commands such as `pacman -Rns`, `paccache -r`, deleting `.pacnew` files, filesystem repairs, service disables, or journal vacuuming unless the user explicitly asks for fixes and the specific action is justified.
- Do not use `--noconfirm` for system updates unless the user explicitly requests it.
- Before using privileged commands, prefer `sudo -n true` to check whether non-interactive sudo is available. If it is not available, report the exact command for the user to run rather than creating authentication failures.
- Treat `.pacnew` and `.pacsave` files as requiring review. Never overwrite configuration blindly.
- For AUR updates, prefer the locally installed helper (`yay`, `paru`) only if present. Do not install an AUR helper as part of this skill.
- If a kernel package was upgraded and the running kernel differs from installed modules, recommend rebooting instead of attempting live repair.

## Maintenance Coverage

The bundled script checks:

- Arch identity and kernel/runtime basics.
- Pending repo updates via `checkupdates` when available, falling back to `pacman -Qu`.
- Foreign/AUR packages and AUR helper availability.
- Failed system and user systemd units.
- High-priority journal entries from the current boot.
- `.pacnew` and `.pacsave` files.
- Orphaned packages.
- Pacman cache size and cleanup opportunity.
- Pacman lock state and interrupted transaction hints.
- Filesystem usage pressure.
- Enabled timers.
- Reboot hints after kernel upgrades.
- Flatpak update state when `flatpak` is installed.

## Common Fix Commands

Only run these when appropriate for the specific findings:

```bash
sudo pacman -Syu
pacdiff
sudo pacman -Rns $(pacman -Qtdq)
sudo paccache -r
sudo systemctl reset-failed
systemctl --user reset-failed
```

When `pacman -Qtdq` returns nothing, do not run `pacman -Rns`.

## Reporting Style

Lead with the highest-risk findings. Include exact commands only for unresolved work. Keep the final answer brief enough to act on.
