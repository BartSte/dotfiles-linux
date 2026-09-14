#!/usr/bin/env bash
# Regression test: zsh setup must create its history file in non-interactive CI.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

mkdir -p "$tmpdir/home" "$tmpdir/bin"
# main explicitly sources ~/.zshenv; keep it empty to model CI without .zshrc settings.
printf ':\n' > "$tmpdir/home/.zshenv"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmpdir/bin/sudo"
chmod +x "$tmpdir/bin/sudo"

# The failure occurs when the non-interactive installer has no configured HISTFILE.
env -u HISTFILE HOME="$tmpdir/home" PATH="$tmpdir/bin:$PATH" bash "$repo_root/zsh/main"
test -f "$tmpdir/home/.histfile"
