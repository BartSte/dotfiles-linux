#!/usr/bin/env bash
# Exercise the actual installed khalorg and khal against synthetic local storage.
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/calendar"
cat > "$tmp/khal.conf" <<EOF
[calendars]
[[synthetic]]
path = $tmp/calendar
type = calendar
[sqlite]
path = $tmp/khal.db
[locale]
timeformat = %H:%M
dateformat = %Y-%m-%d
longdateformat = %Y-%m-%d
datetimeformat = %Y-%m-%d %H:%M
longdatetimeformat = %Y-%m-%d %H:%M
default_timezone = Europe/Berlin
EOF
cat > "$tmp/calendar/event.ics" <<'ICS'
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Synthetic calendar test//EN
BEGIN:VEVENT
UID:synthetic-timed
DTSTAMP:20260101T000000Z
DTSTART:20300101T090000Z
DTEND:20300101T100000Z
SUMMARY:Synthetic timed event
END:VEVENT
END:VCALENDAR
ICS
cat > "$tmp/calendar/all-day.ics" <<'ICS'
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Synthetic calendar test//EN
BEGIN:VEVENT
UID:synthetic-all-day
DTSTAMP:20260101T000000Z
DTSTART;VALUE=DATE:20300102
DTEND;VALUE=DATE:20300103
SUMMARY:Synthetic all-day event
END:VEVENT
END:VCALENDAR
ICS
# Khalorg can select its sibling khal executable, so isolate configuration via XDG.
mkdir -p "$tmp/config/khal"
cp "$tmp/khal.conf" "$tmp/config/khal/config"
export XDG_CONFIG_HOME="$tmp/config"
before=$(sha256sum "$tmp/calendar/"*.ics)
for cycle in 1 2 3; do
    khalorg list -- synthetic 2030-01-01 3d > "$tmp/export.org"
    grep -q 'synthetic-timed' "$tmp/export.org"
    grep -q 'synthetic-all-day' "$tmp/export.org"
    [[ $(sha256sum "$tmp/calendar/"*.ics) == "$before" ]]
done
printf 'PASS: real Khalorg timed/all-day exports preserve calendar payloads and UIDs\n'
cat > "$tmp/new.org" <<'ORG'
* Synthetic created event
  <2030-01-03 Thu 10:00>--<2030-01-03 Thu 11:00>
ORG
khalorg new -- synthetic < "$tmp/new.org" >/dev/null
uid=$(khalorg list --format '{uid}' -- synthetic 2030-01-03 1d | sed '/^[[:space:]]*$/d')
[[ -n $uid && $uid != *$'\n'* ]]
cat > "$tmp/edit.org" <<ORG
* Synthetic edited event
  <2030-01-03 Thu 10:00>--<2030-01-03 Thu 11:00>
  :PROPERTIES:
  :UID: $uid
  :END:
ORG
khalorg edit -- synthetic < "$tmp/edit.org" >/dev/null
for cycle in 1 2 3; do
    khalorg list -- synthetic 2030-01-03 1d > "$tmp/edited.org"
    grep -q 'Synthetic edited event' "$tmp/edited.org"
    grep -q "$uid" "$tmp/edited.org"
    [[ $(khalorg list --format '{uid}' -- synthetic 2030-01-03 1d | sed '/^[[:space:]]*$/d') == "$uid" ]]
done
printf 'PASS: real Khalorg explicit creation and editing preserve event identity\n'
khalorg_bin=$(dirname "$(readlink -f "$(command -v khalorg)")")
"$khalorg_bin/python" - <<'PY'
import datetime
from icalendar import Alarm
from khal.khalendar.event import Event
alarm = Alarm()
alarm.add('ACTION', 'DISPLAY')
before = alarm.to_ical()
assert Event._can_handle_alarm(alarm) is False
assert alarm.to_ical() == before
alarm.add('TRIGGER', datetime.timedelta(minutes=-15))
assert Event._can_handle_alarm(alarm) is True
print('PASS: invalid reminder display does not change metadata; valid reminder retained')
PY
