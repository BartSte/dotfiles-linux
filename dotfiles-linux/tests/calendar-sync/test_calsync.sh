#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
subject="$repo_root/dotfiles-linux/bin/calsync"
tmp=$(mktemp -d)
trap 'if [[ ${KEEP_TEST_TMP:-0} == 1 ]]; then printf "test_tmp=%s\\n" "$tmp" >&2; else rm -rf "$tmp"; fi' EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local expected=$1 actual=$2 label=$3
    [[ $actual == "$expected" ]] || fail "$label: expected [$expected], got [$actual]"
}

setup_case() {
    case_dir=$(mktemp -d "$tmp/case.XXXXXX")
    fake_bin="$case_dir/bin"
    mkdir -p "$fake_bin" "$case_dir/state" "$case_dir/data"
    export TEST_EVENT_LOG="$case_dir/events"
    export TEST_VDIR_COUNT="$case_dir/vdir-count"
    export TEST_VDIR_PID="$case_dir/vdir-pid"
    export TEST_DAVMAIL_PID="$case_dir/davmail-pid"
    export XDG_STATE_HOME="$case_dir/state"
    export XDG_DATA_HOME="$case_dir/data"
    export TEST_UNRELATED_PID=$$
    export LOGNAME=tester USER=tester
    : > "$TEST_EVENT_LOG"
    printf '0\n' > "$TEST_VDIR_COUNT"
    printf '0\n' > "$case_dir/ss-count"
    export TEST_SS_COUNT="$case_dir/ss-count"
    printf 'davmail.caldavPort=1080\n' > "$case_dir/davmail.properties"

    cat > "$fake_bin/pgrep" <<'SH'
#!/usr/bin/env bash
if [[ " $* " == *" -f "* ]]; then [[ ${PREEXISTING_DAVMAIL:-0} == 1 ]]; exit; fi
if [[ " $* " == *" -u "* ]]; then exit 0; fi
exit 1
SH
    cat > "$fake_bin/ping" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    cat > "$fake_bin/davmail" <<'SH'
#!/usr/bin/env bash
printf 'davmail|%s\n' "$*" >> "$TEST_EVENT_LOG"
printf '%s\n' "$$" > "$TEST_DAVMAIL_PID"
if [[ ${IGNORE_DAVMAIL_TERM:-0} == 1 ]]; then
    trap '' TERM
else
    trap 'exit 0' TERM INT HUP
fi
while :; do sleep 1; done
SH
    cat > "$fake_bin/vdirsyncer" <<'SH'
#!/usr/bin/env bash
n=$(cat "$TEST_VDIR_COUNT")
n=$((n + 1))
printf '%s\n' "$n" > "$TEST_VDIR_COUNT"
printf '%s\n' "$$" > "$TEST_VDIR_PID"
printf 'vdirsyncer|%s\n' "$*" >> "$TEST_EVENT_LOG"
[[ ${FAIL_VDIR_CALL:-0} == "$n" ]] && exit 42
if [[ ${BLOCK_VDIR_CALL:-0} == "$n" ]]; then
    trap 'exit 0' TERM INT HUP
    while :; do sleep 1; done
fi
exit 0
SH
    cat > "$fake_bin/khalorg" <<'SH'
#!/usr/bin/env bash
printf 'khalorg|%s\n' "$*" >> "$TEST_EVENT_LOG"
[[ ${FAIL_KHALORG:-0} == 1 ]] && { printf "partial output"; exit 43; }
printf "* Synthetic event\n  <2030-01-01 Tue>\n"
exit 0
SH
    cat > "$fake_bin/nc" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    cat > "$fake_bin/ss" <<'SH'
#!/usr/bin/env bash
n=$(cat "$TEST_SS_COUNT")
n=$((n + 1))
printf '%s\n' "$n" > "$TEST_SS_COUNT"
if [[ ${UNRELATED_LISTENER:-0} == 1 || ( ${LATE_UNRELATED_LISTENER:-0} == 1 && $n -gt 1 ) ]]; then
    printf 'LISTEN 0 50 127.0.0.1:1080 0.0.0.0:* users:(("other",pid=%s,fd=3))\n' "$TEST_UNRELATED_PID"
elif [[ ${DAVMAIL_READY:-1} == 1 && -s $TEST_DAVMAIL_PID ]] && kill -0 "$(cat "$TEST_DAVMAIL_PID")" 2>/dev/null; then
    pid=$(cat "$TEST_DAVMAIL_PID")
    printf 'LISTEN 0 50 127.0.0.1:1080 0.0.0.0:* users:(("java",pid=%s,fd=42))\n' "$pid"
fi
SH
    chmod +x "$fake_bin"/*
    export PATH="$fake_bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

run_subject() {
    timeout --kill-after=2s 10s "$subject" --verbose \
        "$case_dir/davmail.properties" synthetic_calendar "$case_dir/calendar.org" \
        today 365d
}

# Normal execution synchronizes the local calendar, then exports through Khalorg.
setup_case
run_subject || fail "normal run returned non-zero"
mapfile -t events < "$TEST_EVENT_LOG"
assert_eq 3 "${#events[@]}" "normal event count"
[[ ${events[0]} == davmail\|* ]] || fail "DavMail was not started first"
assert_eq 'vdirsyncer|-v CRITICAL sync synthetic_calendar' "${events[1]}" "first vdirsyncer call"
assert_eq "khalorg|list -- synthetic_calendar today 365d" "${events[2]}" "read-only export invocation"
[[ ${events[2]} != *--delete-on-sync* ]] || fail "destructive flag reached Khalorg"
[[ ${events[2]} != *--edit-dates* ]] || fail "date-edit flag reached Khalorg"
pid=$(cat "$TEST_DAVMAIL_PID")
kill -0 "$pid" 2>/dev/null && fail "owned DavMail process survived successful run"

# mycalsync appends its flags after the positional arguments.
setup_case
"$subject" "$case_dir/davmail.properties" synthetic_calendar "$case_dir/calendar.org" today 365d --quiet \
    || fail "trailing quiet option was rejected"

# Exports never ingest existing Org text, and failed exports preserve it.
for old_text in '' 'damaged text without a UID'; do
    setup_case
    printf '%s' "$old_text" > "$case_dir/calendar.org"
    cp "$case_dir/calendar.org" "$case_dir/original.org"
    export FAIL_KHALORG=1
    if run_subject; then fail "partial export succeeded"; fi
    unset FAIL_KHALORG
    cmp "$case_dir/original.org" "$case_dir/calendar.org" || fail "failed export replaced the agenda"
    [[ -z $(find "$case_dir" -name '.agenda.*' -print) ]] || fail "temporary export survived failure"
    run_subject || fail "recovery export failed"
    grep -q 'Synthetic event' "$case_dir/calendar.org" || fail "agenda was not refreshed"
    before=$(stat -c %Y "$case_dir/calendar.org")
    run_subject || fail "repeated export failed"
    assert_eq "$before" "$(stat -c %Y "$case_dir/calendar.org")" "unchanged export timestamp"
done

# Removed request mode cannot invoke calendar operations.
setup_case
if "$subject" --request fake.json; then fail "removed request mode was accepted"; fi
[[ ! -s $TEST_EVENT_LOG ]] || fail "request mode caused side effects"

# A Khalorg failure stops before outbound vdirsyncer and still cleans up owned DavMail.
setup_case
export FAIL_KHALORG=1
if run_subject; then fail "Khalorg failure was masked"; fi
unset FAIL_KHALORG
assert_eq 1 "$(cat "$TEST_VDIR_COUNT")" "vdirsyncer calls after Khalorg failure"
pid=$(cat "$TEST_DAVMAIL_PID")
kill -0 "$pid" 2>/dev/null && fail "owned DavMail process survived Khalorg failure"

# A failed remote synchronization does not replace the previous agenda.
setup_case
printf 'last good agenda' > "$case_dir/calendar.org"
export FAIL_VDIR_CALL=1
if run_subject; then fail "vdirsyncer failure was masked"; fi
unset FAIL_VDIR_CALL
assert_eq 'last good agenda' "$(cat "$case_dir/calendar.org")" "agenda after remote failure"

# Caller cannot append arbitrary Khalorg arguments.
setup_case
if timeout 10s "$subject" -q "$case_dir/davmail.properties" synthetic_calendar \
    "$case_dir/calendar.org" today 365d unexpected-extra; then
    fail "unexpected extra argument was accepted"
fi
[[ ! -s $TEST_EVENT_LOG ]] || fail "side effects occurred before rejecting extra argument"

# Concurrent calendar workers are rejected before any side effect.
setup_case
exec {held_lock_fd}> "$XDG_STATE_HOME/calsync.lock"
flock -n "$held_lock_fd" || fail "could not acquire test lock"
if run_subject; then fail "concurrent wrapper was not rejected"; fi
flock -u "$held_lock_fd"
exec {held_lock_fd}>&-
[[ ! -s $TEST_EVENT_LOG ]] || fail "sync side effects occurred while lock was held"

# A pre-existing DavMail process is ambiguous because work and personal use the
# same listener port. Fail closed instead of reusing an unverified profile.
setup_case
export PREEXISTING_DAVMAIL=1
if run_subject; then fail "ambiguous pre-existing DavMail process was reused"; fi
unset PREEXISTING_DAVMAIL
[[ ! -s $TEST_EVENT_LOG ]] || fail "sync side effects occurred with ambiguous DavMail"

# An unrelated listener on the configured port must not be accepted as the
# readiness signal for an owned DavMail child.
setup_case
export UNRELATED_LISTENER=1
if run_subject; then fail "unrelated listener was accepted as owned DavMail"; fi
unset UNRELATED_LISTENER
[[ ! -s $TEST_EVENT_LOG ]] || fail "sync side effects occurred with occupied DavMail port"
[[ ! -e $TEST_DAVMAIL_PID ]] || fail "DavMail was started on an occupied port"

# A listener that appears after the pre-start port check is still rejected
# unless its PID belongs to the owned DavMail process group.
setup_case
export LATE_UNRELATED_LISTENER=1
if run_subject; then fail "late unrelated listener was accepted as owned DavMail"; fi
unset LATE_UNRELATED_LISTENER
assert_eq 0 "$(cat "$TEST_VDIR_COUNT")" "vdirsyncer calls with late unrelated listener"
pid=$(cat "$TEST_DAVMAIL_PID")
kill -0 "$pid" 2>/dev/null && fail "DavMail survived late-listener readiness failure"

# Listener readiness is required before any vdirsyncer operation.
setup_case
export DAVMAIL_READY=0
if run_subject; then
    fail "wrapper continued before DavMail listener readiness"
fi
unset DAVMAIL_READY
assert_eq 0 "$(cat "$TEST_VDIR_COUNT")" "vdirsyncer calls without listener readiness"
pid=$(cat "$TEST_DAVMAIL_PID")
kill -0 "$pid" 2>/dev/null && fail "DavMail survived listener-readiness failure"

# Cleanup must escalate if an owned DavMail process ignores TERM.
setup_case
export IGNORE_DAVMAIL_TERM=1
if ! run_subject; then
    fail "bounded cleanup did not terminate TERM-ignoring DavMail"
fi
unset IGNORE_DAVMAIL_TERM
pid=$(cat "$TEST_DAVMAIL_PID")
kill -0 "$pid" 2>/dev/null && fail "TERM-ignoring DavMail survived bounded cleanup"

# Signals sent only to the wrapper must terminate both the active stage and
# owned DavMail, while preserving conventional shell signal statuses.
assert_signal_cleanup() {
    local signal=$1 expected_status=$2 wrapper_pid wrapper_status pid pid_file
    setup_case
    export BLOCK_VDIR_CALL=1
    "$subject" -q "$case_dir/davmail.properties" synthetic_calendar \
        "$case_dir/calendar.org" today 365d &
    wrapper_pid=$!
    for _ in {1..50}; do
        [[ $(cat "$TEST_VDIR_COUNT") == 1 ]] && break
        sleep 0.1
    done
    assert_eq 1 "$(cat "$TEST_VDIR_COUNT")" "blocked vdirsyncer did not start for $signal"
    kill "-$signal" "$wrapper_pid"
    for _ in {1..50}; do
        kill -0 "$wrapper_pid" 2>/dev/null || break
        sleep 0.1
    done
    if kill -0 "$wrapper_pid" 2>/dev/null; then
        kill -KILL "$wrapper_pid" 2>/dev/null || true
        fail "wrapper did not terminate after $signal"
    fi
    set +e
    wait "$wrapper_pid"
    wrapper_status=$?
    set -e
    unset BLOCK_VDIR_CALL
    assert_eq "$expected_status" "$wrapper_status" "wrapper $signal status"
    for pid_file in "$TEST_DAVMAIL_PID" "$TEST_VDIR_PID"; do
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
            fail "owned child survived wrapper $signal: $pid"
        fi
    done
}

assert_signal_cleanup HUP 129

assert_timed_signal_cleanup() {
    local signal=$1 expected_status=$2 wrapper_status pid pid_file
    setup_case
    export BLOCK_VDIR_CALL=1
    set +e
    timeout --preserve-status --signal="$signal" --kill-after=5s 1s \
        "$subject" -q "$case_dir/davmail.properties" synthetic_calendar \
        "$case_dir/calendar.org" today 365d
    wrapper_status=$?
    set -e
    unset BLOCK_VDIR_CALL
    assert_eq "$expected_status" "$wrapper_status" "wrapper $signal status"
    for pid_file in "$TEST_DAVMAIL_PID" "$TEST_VDIR_PID"; do
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
            fail "owned child survived wrapper $signal: $pid"
        fi
    done
}

assert_timed_signal_cleanup INT 130
assert_timed_signal_cleanup TERM 143

if grep -q -- '--delete-on-sync\|--edit-dates' "$subject"; then
    fail "production wrapper contains prohibited Khalorg flags"
fi

printf 'PASS: calsync wrapper contract\n'
