#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
export XDG_STATE_HOME="$test_root/state with spaces"
mkdir -p "$test_root/bin with spaces"
export PATH="$test_root/bin with spaces:$PATH"
export TEST_RBW_CONFIG=$test_root/config.json TEST_PINENTRY_CALLS=$test_root/calls
printf '{"email":"synthetic-%s@example.invalid","base_url":null,"identity_url":null,"pinentry":"pinentry"}\n' \
    "$(basename "$test_root")" > "$TEST_RBW_CONFIG"

cat > "$test_root/bin with spaces/rbw" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
    'config show') cat "$TEST_RBW_CONFIG" ;;
    'config set pinentry '*)
        jq --arg value "$4" '.pinentry = $value' "$TEST_RBW_CONFIG" > "$TEST_RBW_CONFIG.tmp"
        mv "$TEST_RBW_CONFIG.tmp" "$TEST_RBW_CONFIG"
        ;;
    stop-agent) ;;
    *) exit 2 ;;
esac
SH
cat > "$test_root/bin with spaces/pinentry" <<'SH'
#!/usr/bin/env bash
printf 'called\n' >> "$TEST_PINENTRY_CALLS"
printf 'OK synthetic pinentry\n'
while IFS= read -r command; do
    case "$command" in
        GETPIN)
            if [[ ${TEST_CANCEL:-0} == 1 ]]; then
                printf 'ERR 83886179 cancelled\n'
                exit 1
            fi
            printf 'D %s\nOK\n' "${TEST_PIN:-synthetic%25password%0Awith spaces-é}"
            exit 0
            ;;
        *) printf 'OK\n' ;;
    esac
done
SH
chmod +x "$test_root/bin with spaces/rbw" "$test_root/bin with spaces/pinentry"

unlock_dir=$root/bitwarden
# shellcheck source=bitwarden/windows-common.sh
source "$unlock_dir/windows-common.sh"
initialize_windows_unlock
cleanup() {
    windows_secret Delete </dev/null >/dev/null 2>&1 || true
    rm -rf -- "$test_root"
}
trap cleanup EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
request() {
    printf 'SETTITLE rbw\nSETPROMPT %s\nSETDESC synthetic test\n' "$1"
    if [[ ${2:-} == retry ]]; then printf 'SETERROR Incorrect password\n'; fi
    printf 'GETPIN\n'
}
helper=$root/bin/rbw-pinentry-windows
manager=$root/bin/rbw-windows-unlock

windows_secret SelfTest </dev/null >/dev/null || fail 'DPAPI unavailable'
if printf '' | windows_secret Write >/dev/null 2>&1; then fail 'empty secret was accepted'; fi
"$manager" enable >/dev/null
status=$("$manager" status)
[[ $status == *'Helper: enabled'* ]] || fail 'helper was not enabled'
response=$(request 'Master Password' | "$helper" --timeout 0)
[[ $response == *'D synthetic%25password%0Awith spaces-é'* ]] || fail 'enrollment changed encoding'
windows_secret Status </dev/null || fail 'secret was not stored'
[[ $(wc -l < "$TEST_PINENTRY_CALLS") == 1 ]] || fail 'enrollment did not prompt exactly once'
response=$(request 'Master Password' | "$helper" --timeout 0)
[[ $response == *'D synthetic%25password%0Awith spaces-é'* ]] || fail 'DPAPI retrieval changed encoding'
[[ $(wc -l < "$TEST_PINENTRY_CALLS") == 1 ]] || fail 'cached unlock prompted again'

export TEST_PIN=123456
response=$(request 'Authenticator Code' | "$helper")
[[ $response == *'D 123456'* ]] || fail '2FA did not use original pinentry'
[[ $(windows_secret Read </dev/null) == 'synthetic%25password%0Awith spaces-é' ]] || fail '2FA overwrote the master secret'
export TEST_PIN='replacement%25password'
response=$(request 'Master Password' retry | "$helper")
[[ $response == *'D replacement%25password'* ]] || fail 'retry reused a rejected secret'
[[ $(windows_secret Read </dev/null) == 'replacement%25password' ]] || fail 'retry did not replace the secret'

export TEST_CANCEL=1
if request 'Master Password' retry | "$helper" > "$test_root/cancelled"; then fail 'cancellation succeeded'; fi
if windows_secret Status </dev/null; then fail 'rejected secret survived cancellation'; fi
if grep -q '^D ' "$test_root/cancelled"; then fail 'cancellation returned secret data'; fi
unset TEST_CANCEL
request 'Master Password' | "$helper" >/dev/null
"$manager" disable >/dev/null
[[ $(rbw config show | jq -r '.pinentry') == pinentry ]] || fail 'previous pinentry was not restored'
"$manager" forget >/dev/null
if windows_secret Status </dev/null; then fail 'forget retained the secret'; fi
if "$manager" invalid >/dev/null 2>&1; then fail 'invalid action succeeded'; fi
if "$manager" enable extra >/dev/null 2>&1; then fail 'extra argument succeeded'; fi
printf 'PASS: Windows DPAPI enrollment, cached unlock, encoding, 2FA, retries, cancellation, and rollback\n'
