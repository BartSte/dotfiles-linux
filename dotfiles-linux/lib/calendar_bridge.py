"""Explicit calendar requests. Org projections never act as write queues.

The calsync parent holds the cross-process lock and owns remote synchronization.
This module changes local storage only. A local confirmation is not Outlook success.
"""
import hashlib
import json
import os
import re
import tempfile
import uuid
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from icalendar import Calendar, Event
from khalorg.org.agenda_items import OrgAgendaFile

MAX_BYTES = 2 * 1024 * 1024
CALENDARS = {'outlook_work', 'outlook_personal'}


class Rejected(ValueError):
    """An edit that must remain pending for user review."""


def digest(content):
    return hashlib.sha256(content).hexdigest()


def read_bytes(path):
    if path.is_symlink():
        raise Rejected('Symbolic links are not accepted for calendar data.')
    with path.open('rb') as stream:
        content = stream.read(MAX_BYTES + 1)
    if len(content) > MAX_BYTES:
        raise Rejected('Calendar input exceeds the size limit.')
    return content


def atomic_write(path, content):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.calendar-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def intent(event):
    """Compare requested fields, allowing server timestamp and byte rewrites."""
    def stamp(key):
        value = event.decoded(key)
        if isinstance(value, datetime):
            if value.tzinfo is None:
                raise Rejected('Floating calendar times are not supported.')
            return value.astimezone(timezone.utc).isoformat()
        return value.isoformat()
    return {key: str(event.get(key, '')) for key in ('UID', 'SUMMARY', 'DESCRIPTION', 'LOCATION')} | {
        'start': stamp('DTSTART'), 'end': stamp('DTEND'),
        'attendees': [str(value) for value in (event.get('ATTENDEE') if isinstance(event.get('ATTENDEE'), list) else [event.get('ATTENDEE')]) if value],
    }


def save_json(path, data):
    atomic_write(path, (json.dumps(data, ensure_ascii=False) + '\n').encode())


def validate_request(request):
    if not isinstance(request, dict) or set(request) != {'version', 'action', 'calendar', 'request_id', 'org'}:
        raise Rejected('Invalid request fields.')
    if type(request['version']) is not int or request['version'] != 1:
        raise Rejected('Unsupported request version.')
    if request['calendar'] not in CALENDARS or request['action'] not in {'edit', 'new'}:
        raise Rejected('Only explicit new and edit requests are supported.')
    try:
        if str(uuid.UUID(request['request_id'])) != request['request_id']:
            raise ValueError()
    except (ValueError, TypeError, AttributeError):
        raise Rejected('Invalid request identifier.') from None
    if not isinstance(request['org'], str) or len(request['org'].encode()) > MAX_BYTES:
        raise Rejected('Invalid event text.')


class Bridge:
    def __init__(self, calendar_dir, state_dir, calendar, timezone):
        self.calendar_dir = Path(calendar_dir)
        self.state_dir = Path(state_dir)
        self.calendar = calendar
        self.timezone = timezone

    def request_path(self, request_id):
        # Callers validate the UUID before this identifier becomes a filename.
        return self.state_dir / 'requests' / (request_id + '.json')

    def find(self, uid, missing_ok=False):
        found = []
        for path in self.calendar_dir.glob('*.ics'):
            raw = read_bytes(path)
            parsed = Calendar.from_ical(raw)
            events = parsed.walk('VEVENT')
            if any(str(event.get('UID', '')) == uid for event in events):
                found.append((path, raw, parsed, events))
        if not found and missing_ok:
            return None
        if len(found) != 1:
            raise Rejected('Calendar event is missing or ambiguous.')
        return found[0]

    def parse(self, request):
        text = request['org']
        if len(re.findall(r'^\*+ ', text, re.M)) != 1:
            raise Rejected('Submit exactly one complete event heading.')
        if len(re.findall(r'^\s*:PROPERTIES:\s*$', text, re.M)) != 1 or len(re.findall(r'^\s*:END:\s*$', text, re.M)) != 1:
            raise Rejected('The event property drawer is missing or damaged.')
        # Duplicate properties must not silently replace the UID or baseline.
        drawer = re.search(r':PROPERTIES:[ \t]*\n(.*?)^[ \t]*:END:', text, re.M | re.S)
        if not drawer:
            raise Rejected('The event property drawer is damaged.')
        names = re.findall(r'^\s*:([A-Za-z_]+):', drawer[1], re.M)
        if len(set(names)) != len(names):
            raise Rejected('Duplicate event properties are not accepted.')
        try:
            items = OrgAgendaFile.from_str(text).items
            if len(items) != 1 or len(items[0].timestamps) != 1:
                raise ValueError()
            item = items[0]
            if not item.title or item.first_timestamp._repeater:
                raise ValueError()
        except Exception as error:
            raise Rejected('The event timestamp is missing, damaged, or recurring.') from error
        if any(item.properties.get(key) for key in ('ATTENDEES', 'ORGANIZER', 'RRULE', 'UNTIL')):
            raise Rejected('Use Outlook for invitations and recurring events.')
        if item.properties.get('CALENDAR', self.calendar) != self.calendar:
            raise Rejected('The event belongs to another calendar.')
        return item

    def apply(self, request):
        validate_request(request)
        if request['calendar'] != self.calendar:
            raise Rejected('The request belongs to another calendar.')
        path = self.request_path(request['request_id'])
        if path.exists():
            record = json.loads(read_bytes(path))
            if record['request'] != request:
                raise Rejected('This request identifier already belongs to another edit.')
            if 'expected' in record:
                existing = self.find(record['uid'], missing_ok=True)
                if existing and len(existing[3]) == 1 and intent(existing[3][0]) == record['intent']:
                    return {'status': 'applied_local', 'uid': record['uid']}
                # Never overwrite a changed event to repair a retry.
                raise Rejected('The event changed after this request. Keep the pending edit.')
        else:
            record = {'request': request, 'status': 'pending'}
            save_json(path, record)
        item = self.parse(request)
        if request['action'] == 'edit':
            uid = item.uid
            baseline = item.properties.get('BRIDGE_BASELINE', '')
            if not uid or not re.fullmatch(r'[0-9a-f]{64}', baseline):
                raise Rejected('An edit requires its UID and exported baseline.')
            event_path, raw, parsed, events = self.find(uid)
            if digest(raw) != baseline:
                raise Rejected('Calendar event changed. Keep the pending edit for review.')
            if len(events) != 1 or any(key in events[0] for key in ('RRULE', 'RDATE', 'EXDATE', 'RECURRENCE-ID', 'ATTENDEE', 'ORGANIZER')):
                raise Rejected('Use Outlook for invitations and recurring events.')
            event = events[0]
            for key in ('URL', 'STATUS', 'CATEGORIES'):
                current = event.get(key, '')
                if key == 'CATEGORIES' and key in event:
                    # Match khal export and khalorg's escaped-comma normalization.
                    current = current.to_ical().decode('utf-8').replace(r'\,', ',')
                if str(item.properties.get(key, '')) != str(current):
                    raise Rejected('This field cannot be edited here: ' + key)
        else:
            for key in ('URL', 'STATUS', 'CATEGORIES'):
                if item.properties.get(key):
                    raise Rejected('This field cannot be set for new events here: ' + key)
            if item.uid or item.properties.get('BRIDGE_BASELINE'):
                raise Rejected('New events must not contain an existing UID or baseline.')
            uid = request['request_id'] + '@org-calendar.invalid'
            if self.find(uid, missing_ok=True):
                raise Rejected('This creation already exists. Keep the original request.')
            event_path = self.calendar_dir / (request['request_id'] + '.ics')
            if event_path.exists():
                raise Rejected('The new event filename already exists.')
            parsed = Calendar()
            parsed.add('VERSION', '2.0')
            parsed.add('PRODID', '-//Bart//Explicit calendar bridge//EN')
            event = Event()
            event.add('UID', uid)
            parsed.add_component(event)
        for key, value in [('SUMMARY', item.title), ('DESCRIPTION', item.description), ('LOCATION', item.properties.get('LOCATION', ''))]:
            event.pop(key, None)
            event.add(key, value)
        stamp = item.first_timestamp
        start, end = stamp.start, stamp.end
        if isinstance(start, datetime):
            def localize(value):
                first = value.replace(tzinfo=ZoneInfo(self.timezone), fold=0)
                second = value.replace(tzinfo=ZoneInfo(self.timezone), fold=1)
                if first.utcoffset() != second.utcoffset():
                    raise Rejected('Use Outlook for ambiguous or nonexistent DST times.')
                return first
            start = localize(start)
            end = localize(end) if isinstance(end, datetime) else start + timedelta(hours=1)
            start, end = start.astimezone(timezone.utc), end.astimezone(timezone.utc)
        elif type(start) is date:
            # Org all-day ranges include the last day; iCalendar DTEND excludes it.
            end = (end if type(end) is date else start) + timedelta(days=1)
        else:
            raise Rejected('Invalid event date.')
        if end <= start:
            raise Rejected('The event end must follow its start.')
        for key, value in [('DTSTART', start), ('DTEND', end)]:
            event.pop(key, None)
            event.add(key, value)
        event.pop('DURATION', None)
        sequence = int(event.get('SEQUENCE', 0)) + 1
        event.pop('SEQUENCE', None)
        event.add('SEQUENCE', sequence)
        event.pop('DTSTAMP', None)
        event.add('DTSTAMP', datetime.now(timezone.utc))
        expected = parsed.to_ical()
        record.update(status='prepared', uid=uid, expected=digest(expected), intent=intent(event))
        # Durable receipt precedes the calendar write, so ambiguous failures cannot
        # create a second event. A failed prepared request requires manual review.
        save_json(path, record)
        atomic_write(event_path, expected)
        record['status'] = 'applied_local'
        save_json(path, record)
        return {'status': 'applied_local', 'uid': uid}

    def verify(self, request):
        validate_request(request)
        record = json.loads(read_bytes(self.request_path(request['request_id'])))
        if record['request'] != request or 'expected' not in record:
            raise Rejected('The request has no matching local receipt.')
        _, raw, _, events = self.find(record['uid'])
        if len(events) != 1 or intent(events[0]) != record['intent']:
            raise Rejected('Calendar verification failed. Keep the pending edit.')
        record['status'] = 'confirmed_local'
        save_json(self.request_path(request['request_id']), record)
        return {'status': 'confirmed_local', 'uid': record['uid'], 'baseline': digest(raw)}

    def publish(self, content, target):
        """Publish a projection, keeping any replaced local text for recovery.

        Supported Neovim clients edit separate local drafts, not this projection.
        These snapshots are defense in depth, not distributed locking.
        """
        target = Path(target)
        def annotate(match):
            uid = match.group(1).strip()
            _, raw, _, _ = self.find(uid)
            return match.group(0) + '\n  :BRIDGE_BASELINE: ' + digest(raw)
        rendered = re.sub(r'^\s*:UID: ([^\n]+)$', annotate, content, flags=re.M)
        proposed = rendered.encode()
        if len(proposed) > MAX_BYTES:
            raise Rejected('Calendar projection exceeds the size limit.')
        previous_path = self.state_dir/'exports'/(self.calendar+'.org')
        if target.exists():
            current = read_bytes(target)
            previous = read_bytes(previous_path) if previous_path.exists() else None
            if current != proposed and current != previous:
                recovery = self.state_dir/'projections'/(self.calendar+'.'+digest(current)+'.org')
                atomic_write(recovery, current)
        atomic_write(target, proposed)
        atomic_write(previous_path, proposed)


def main():
    import sys
    from khal.settings.settings import find_configuration_file, get_config
    if len(sys.argv) < 4 or sys.argv[1] not in {'export', 'apply', 'verify'} or sys.argv[2] not in CALENDARS:
        raise Rejected('Use export, apply, or verify with an allowed calendar.')
    action, calendar = sys.argv[1:3]
    import socket
    marker = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home()/'.config')))/'calendar-bridge/server'
    if not marker.is_file() or read_bytes(marker).decode().strip() != socket.gethostname():
        raise Rejected('This host is not the calendar server.')
    config = get_config(find_configuration_file())
    calendar_dir = Path(config['calendars'][calendar]['path']).expanduser()
    if not calendar_dir.is_dir():
        raise Rejected('The configured calendar directory does not exist.')
    state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state')))/'calendar-bridge'
    zone = str(config['locale']['default_timezone'])
    service = Bridge(calendar_dir, state, calendar, zone)
    if action == 'export':
        if len(sys.argv) != 6:
            raise Rejected('Export requires a destination and date range.')
        from khalorg.commands import list_command
        template = '* {title}\n  {timestamps}\n  :PROPERTIES:\n  :UID: {uid}\n  :CALENDAR: {calendar}\n  :LOCATION: {location}\n  :URL: {url}\n  :STATUS: {status}\n  :CATEGORIES: {categories}\n  :ATTENDEES: {attendees}\n  :ORGANIZER: {organizer}\n  :RRULE: {rrule}\n  :UNTIL: {until_rrule}\n  :END:\n  {description}\n'
        content = list_command(calendar=calendar, start=sys.argv[4], stop=sys.argv[5], khalorg_format=template)
        service.publish(content, Path(sys.argv[3]))
    else:
        if len(sys.argv) != 4:
            raise Rejected('Apply and verify require one request file.')
        request = json.loads(read_bytes(Path(sys.argv[3])))
        result = getattr(service, action)(request)
        result.update(calendar=calendar, request_id=request['request_id'])
        print(json.dumps(result))


if __name__ == '__main__':
    import sys
    try:
        main()
    except Rejected as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(2)
    except Exception:
        # Do not print event contents, private paths, or exception payloads.
        print('Calendar bridge failed. The pending request remains available.', file=sys.stderr)
        raise SystemExit(1)
