#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/state with spaces"
cat > "$tmp/bin/khalorg" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@"
cat
SH
chmod +x "$tmp/bin/khalorg"
export PATH="$tmp/bin:$PATH" XDG_STATE_HOME="$tmp/state with spaces"
subject="$source_dir/bin/khalorg-local"
result=$(printf 'event with spaces\n' | "$subject" edit -- outlook_work)
[[ $result == $'edit\n--\noutlook_work\nevent with spaces' ]]
for command in sync delete ''; do
    if "$subject" "$command" outlook_work; then
        printf 'Unsafe action accepted: %s\n' "$command" >&2
        exit 1
    fi
done
"$subject" sync --help >/dev/null
exec {lock_fd}> "$XDG_STATE_HOME/calsync.lock"
flock "$lock_fd"
if timeout 1s "$subject" list -- outlook_work; then
    printf 'Plugin adapter bypassed the sync lock.\n' >&2
    exit 1
fi
flock -u "$lock_fd"
"$subject" list -- outlook_work >/dev/null
printf 'PASS: local plugin adapter and shared lock\n'
