#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
export TWG_TEST_ROOT="$tmpdir"
mkdir -p "$tmpdir/bin"
cat > "$tmpdir/payload" <<'BINARY'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TWG_TEST_ROOT/auth-calls"
exit "${TWG_TEST_AUTH_STATUS:-0}"
BINARY
cat > "$tmpdir/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
[[ "${TWG_TEST_DOWNLOAD_FAILURE:-}" != true ]] || exit 22
url=$4
output=$6
case "$url" in
    */SHA256SUMS-v*)
        checksum=$(sha256sum "$TWG_TEST_ROOT/payload")
        checksum=${checksum%% *}
        [[ "${TWG_TEST_BAD_CHECKSUM:-}" != true ]] || checksum=$(printf '%064d' 0)
        printf '%s  %s\n' "$checksum" "${TWG_TEST_CHECKSUM_NAME:-twg-linux-x64-v1.3.8}" > "$output"
        ;;
    */twg-linux-x64-v1.3.8) cp "$TWG_TEST_ROOT/payload" "$output" ;;
    *) exit 1 ;;
esac
CURL
chmod +x "$tmpdir/bin/curl"
# Exclude any real twg binary from PATH.
for cmd in bash uname mktemp rm awk sha256sum mkdir install cp; do
    ln -s "$(command -v "$cmd")" "$tmpdir/bin/$cmd"
done
export PATH="$tmpdir/bin"

for ci in true false ''; do
    export HOME="$tmpdir/home-$ci"
    CI="$ci" bash "$repo_root/twg/main"
    [[ -x "$HOME/.local/bin/twg" ]]
    [[ ! -e "$tmpdir/auth-calls" ]]
    # A repeat install must succeed without downloads.
    TWG_TEST_DOWNLOAD_FAILURE=true bash "$repo_root/twg/main"
done

for failure in TWG_TEST_BAD_CHECKSUM TWG_TEST_DOWNLOAD_FAILURE; do
    export HOME="$tmpdir/$failure"
    export "$failure=true"
    if bash "$repo_root/twg/main"; then
        echo "Expected failure: $failure" >&2
        exit 1
    fi
    unset "$failure"
    [[ ! -e "$HOME/.local/bin/twg" ]]
done
export HOME="$tmpdir/missing-checksum"
if TWG_TEST_CHECKSUM_NAME=wrong-file bash "$repo_root/twg/main"; then
    echo 'Expected missing checksum failure' >&2
    exit 1
fi

export HOME="$tmpdir/home-true"
bash "$repo_root/twg/auth"
[[ "$(< "$tmpdir/auth-calls")" == $'consent\nlogin' ]]
rm "$tmpdir/auth-calls"
if TWG_TEST_AUTH_STATUS=7 bash "$repo_root/twg/auth"; then
    echo 'Expected consent failure' >&2
    exit 1
fi
[[ "$(< "$tmpdir/auth-calls")" == consent ]]
echo 'twg setup and auth tests passed'
