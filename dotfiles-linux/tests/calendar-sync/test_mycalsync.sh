#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
subject="$repo_root/dotfiles-linux/bin/mycalsync"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fake_bin="$tmp/bin"
mkdir -p "$fake_bin"
export TEST_EVENT_LOG="$tmp/events"
: > "$TEST_EVENT_LOG"

cat > "$fake_bin/calsync" <<'SH'
#!/usr/bin/env bash
printf 'calsync|%s\n' "$*" >> "$TEST_EVENT_LOG"
case " $* " in
    *" outlook_work "*) [[ ${FAIL_CALENDAR:-} == work ]] && exit 41 ;;
    *" outlook_personal "*) [[ ${FAIL_CALENDAR:-} == personal ]] && exit 42 ;;
esac
exit 0
SH
chmod +x "$fake_bin/calsync"
export PATH="$fake_bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="$tmp/home"
mkdir -p "$HOME"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

run_subject() {
    "$subject" --quiet
}

run_subject || fail "normal mycalsync run returned non-zero"
mapfile -t events < "$TEST_EVENT_LOG"
[[ ${#events[@]} -eq 2 ]] || fail "expected two calendars, got ${#events[@]}"
[[ ${events[0]} == "calsync|$HOME/.config/davmail/davmail.work.properties outlook_work $HOME/dropbox/org/outlook_work.org today 365d --quiet" ]] || fail "unexpected work invocation: ${events[0]}"
[[ ${events[1]} == "calsync|$HOME/.config/davmail/davmail.personal.properties outlook_personal $HOME/dropbox/org/outlook_personal.org today 365d --quiet" ]] || fail "unexpected personal invocation: ${events[1]}"

: > "$TEST_EVENT_LOG"
export FAIL_CALENDAR=work
if run_subject; then fail "work-calendar failure was masked"; fi
unset FAIL_CALENDAR
mapfile -t events < "$TEST_EVENT_LOG"
[[ ${#events[@]} -eq 1 ]] || fail "personal calendar ran after work failure"

: > "$TEST_EVENT_LOG"
export FAIL_CALENDAR=personal
if run_subject; then fail "personal-calendar failure was masked"; fi
unset FAIL_CALENDAR
mapfile -t events < "$TEST_EVENT_LOG"
[[ ${#events[@]} -eq 2 ]] || fail "unexpected call count on personal failure"

printf 'PASS: mycalsync wrapper contract\n'
