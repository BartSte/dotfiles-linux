#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/system-check"
mkdir -p "$state_dir"

timestamp="$(date +%Y%m%d-%H%M%S)"
log_file="$state_dir/system-check-$timestamp.log"
latest_file="$state_dir/latest.log"

/home/barts/dotfiles-linux/codex/skills/system-check/scripts/arch-system-check.sh >"$log_file" 2>&1
ln -sfn "$log_file" "$latest_file"
printf 'Wrote %s\n' "$log_file"
