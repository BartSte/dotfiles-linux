import hashlib
import importlib.util
import os
import subprocess
import json
from pathlib import Path
import sys
import tempfile
import socket
import re
import unittest
import uuid
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[2] / 'lib/calendar_bridge.py'
spec = importlib.util.spec_from_file_location('calendar_bridge', SOURCE)
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)

class BridgeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR'))
        self.root = Path(self.tmp.name)
        self.calendar = self.root/'calendar'
        self.calendar.mkdir()
        self.path = self.calendar/'event.ics'
        self.original = b'''BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Synthetic//EN\r\nBEGIN:VEVENT\r\nUID:existing@synthetic.invalid\r\nDTSTAMP:20260101T000000Z\r\nDTSTART:20280103T100000Z\r\nDTEND:20280103T110000Z\r\nSUMMARY:Original\r\nLOCATION:Room\r\nDESCRIPTION:Notes\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n'''
        self.path.write_bytes(self.original)
        self.service = bridge.Bridge(self.calendar, self.root/'state', 'outlook_personal', 'Europe/Amsterdam')

    def tearDown(self):
        self.tmp.cleanup()

    def org(self, title='Updated', baseline=None):
        baseline = baseline or hashlib.sha256(self.path.read_bytes()).hexdigest()
        return f'''* {title}\n<2028-01-03 Mon 11:00-12:00>\n:PROPERTIES:\n:UID: existing@synthetic.invalid\n:BRIDGE_BASELINE: {baseline}\n:LOCATION: Room\n:END:\nNotes\n'''

    def request(self, org=None, action='edit', request_id=None):
        return dict(version=1, action=action, calendar='outlook_personal', request_id=request_id or str(uuid.uuid4()), org=org or self.org())

    def test_edit_requires_matching_baseline(self):
        request = self.request(org=self.org(baseline='0'*64))
        with self.assertRaisesRegex(bridge.Rejected, 'changed'):
            self.service.apply(request)
        self.assertEqual(self.original, self.path.read_bytes())
        pending = self.service.request_path(request['request_id'])
        self.assertTrue(pending.exists(), 'Rejected edit must remain recoverable')

    def test_explicit_edit_updates_only_selected_event(self):
        other = self.calendar/'other.ics'
        other.write_bytes(self.original.replace(b'existing@', b'other@'))
        request = self.request()
        response = self.service.apply(request)
        self.assertEqual('applied_local', response['status'])
        self.assertIn(b'SUMMARY:Updated', self.path.read_bytes())
        self.assertEqual(self.original.replace(b'existing@', b'other@'), other.read_bytes())
        self.assertEqual('existing@synthetic.invalid', response['uid'])
        self.assertEqual('confirmed_local', self.service.verify(request)['status'])

    def test_malformed_requests_cannot_write(self):
        variants = []
        for key, value in [('action', 'delete'), ('calendar', 'outlook_work'), ('request_id', '../escape'), ('version', 2)]:
            req = self.request()
            req[key] = value
            variants.append(req)
        for text in ['', '* Damaged\n<2028-01-03 Mon 11:00>\n', self.org().split(':END:')[0], self.org()+self.org(), self.org().replace(':UID: existing@synthetic.invalid', ':UID: missing@synthetic.invalid')]:
            variants.append(self.request(org=text) | {'org': text})
        for request in variants:
            with self.subTest(request=request):
                with self.assertRaises(bridge.Rejected):
                    self.service.apply(request)
                self.assertEqual(self.original, self.path.read_bytes())

    def test_recurring_and_attendee_events_are_rejected(self):
        for line in [b'RRULE:FREQ=WEEKLY', b'ATTENDEE:mailto:test@synthetic.invalid', b'ORGANIZER:mailto:test@synthetic.invalid']:
            raw = self.original.replace(b'END:VEVENT', line+b'\r\nEND:VEVENT')
            self.path.write_bytes(raw)
            with self.assertRaises(bridge.Rejected):
                self.service.apply(self.request())
            self.assertEqual(raw, self.path.read_bytes())

    def test_request_retry_does_not_repeat_a_write(self):
        request = self.request()
        self.service.apply(request)
        after = self.path.read_bytes()
        self.service.apply(request)
        self.assertEqual(after, self.path.read_bytes())
        modified = request | {'org': self.org(title='Another edit')}
        with self.assertRaises(bridge.Rejected):
            self.service.apply(modified)
        self.assertEqual(after, self.path.read_bytes())

    def test_remote_change_after_apply_fails_verification(self):
        request = self.request()
        self.service.apply(request)
        changed = self.path.read_bytes().replace(b'SUMMARY:Updated', b'SUMMARY:Remote edit')
        self.path.write_bytes(changed)
        with self.assertRaises(bridge.Rejected):
            self.service.verify(request)
        self.assertEqual(changed, self.path.read_bytes())

    def test_explicit_create_is_idempotent(self):
        org = '* New event\n<2028-01-03 Mon 13:00-14:00>\n:PROPERTIES:\n:LOCATION: Room\n:END:\nNotes\n'
        request = self.request(org=org, action='new')
        response = self.service.apply(request)
        self.assertEqual(2, len(list(self.calendar.glob('*.ics'))))
        self.assertEqual(self.original, self.path.read_bytes())
        self.service.apply(request)
        self.assertEqual(2, len(list(self.calendar.glob('*.ics'))))
        self.assertEqual(response['uid'], self.service.verify(request)['uid'])
        with self.assertRaises(bridge.Rejected):
            self.service.apply(self.request(action='new'))

    def test_creation_rejects_unsupported_fields_without_calendar_changes(self):
        for key, value in [('URL', 'https://synthetic.invalid/event'), ('STATUS', 'CANCELLED'), ('CATEGORIES', 'Private')]:
            with self.subTest(field=key):
                org = f'* New event\n<2028-01-03 Mon 13:00-14:00>\n:PROPERTIES:\n:{key}: {value}\n:END:\nNotes\n'
                request = self.request(org=org, action='new')
                with self.assertRaisesRegex(bridge.Rejected, key):
                    self.service.apply(request)
                self.assertEqual(self.original, self.path.read_bytes())
                self.assertEqual([self.path], list(self.calendar.glob('*.ics')))
                record = json.loads(self.service.request_path(request['request_id']).read_text())
                self.assertEqual(request, record['request'], 'Rejected creation must retain the exact payload')
                self.assertEqual('pending', record['status'])

    def test_title_edit_preserves_unchanged_exported_categories(self):
        from icalendar import Calendar
        for categories, values in [
            ('Synthetic', ['Synthetic']),
            ('Synthetic,Work', ['Synthetic', 'Work']),
            (r'Synthetic\, special,Work', ['Synthetic, special', 'Work']),
        ]:
            with self.subTest(categories=categories):
                raw = self.original.replace(b'END:VEVENT', b'CATEGORIES:' + categories.encode() + b'\r\nEND:VEVENT')
                self.path.write_bytes(raw)
                org = self.org().replace(':LOCATION: Room', ':LOCATION: Room\n:CATEGORIES: ' + categories)
                self.service.apply(self.request(org=org))
                event = Calendar.from_ical(self.path.read_bytes()).walk('VEVENT')[0]
                self.assertEqual('Updated', str(event['SUMMARY']))
                self.assertEqual(values, [str(value) for value in event['CATEGORIES'].cats])

    def test_category_change_is_rejected_without_calendar_changes(self):
        raw = self.original.replace(b'END:VEVENT', b'CATEGORIES:Synthetic\r\nEND:VEVENT')
        self.path.write_bytes(raw)
        org = self.org().replace(':LOCATION: Room', ':LOCATION: Room\n:CATEGORIES: Different')
        request = self.request(org=org)
        with self.assertRaisesRegex(bridge.Rejected, 'CATEGORIES'):
            self.service.apply(request)
        self.assertEqual(raw, self.path.read_bytes())
        record = json.loads(self.service.request_path(request['request_id']).read_text())
        self.assertEqual(request, record['request'])

    def test_export_never_ingests_removed_or_damaged_entries(self):
        projection = self.root/'projection.org'
        server_org = self.org(title='Original').replace(':BRIDGE_BASELINE: '+hashlib.sha256(self.original).hexdigest()+'\n', '')
        for damaged in [b'', b'\xffbroken', b'* Damaged\n<2028-01-03 Mon 11:00>\n']:
            projection.write_bytes(damaged)
            self.service.publish(server_org, projection)
            self.assertEqual(self.original, self.path.read_bytes())
            self.assertIn(':BRIDGE_BASELINE: '+hashlib.sha256(self.original).hexdigest(), projection.read_text())
            snapshots = list((self.root/'state'/'projections').glob('*.org'))
            self.assertTrue(any(p.read_bytes() == damaged for p in snapshots))

    def test_dates_and_unknown_fields_fail_closed(self):
        from icalendar import Calendar
        for stamp in ['<2028-01-03 Mon>', '<2028-01-03 Mon 13:00-14:00>']:
            self.path.write_bytes(self.original)
            request = self.request(org=self.org().replace('<2028-01-03 Mon 11:00-12:00>', stamp))
            self.service.apply(request)
            event = Calendar.from_ical(self.path.read_bytes()).walk('VEVENT')[0]
            self.assertEqual('existing@synthetic.invalid', str(event['UID']))
            self.assertGreater(event.decoded('DTEND'), event.decoded('DTSTART'))
        self.path.write_bytes(self.original)
        with self.assertRaises(bridge.Rejected):
            self.service.apply(self.request(org=self.org().replace(':LOCATION: Room', ':LOCATION: Room\n:URL: https://changed.invalid')))
        self.assertEqual(self.original, self.path.read_bytes())

    def test_dst_ambiguous_or_nonexistent_times_are_rejected(self):
        for stamp in ['<2028-03-26 Sun 02:30-03:30>', '<2028-10-29 Sun 02:30-03:30>']:
            with self.assertRaises(bridge.Rejected):
                self.service.apply(self.request(org=self.org().replace('<2028-01-03 Mon 11:00-12:00>', stamp)))
            self.assertEqual(self.original, self.path.read_bytes())

    def test_cli_exports_and_verifies_in_isolated_home(self):
        config = self.root/'config/khal'
        config.mkdir(parents=True)
        (config/'config').write_text(f"""[calendars]
[[outlook_personal]]
path = {self.calendar}
type = calendar
[sqlite]
path = {self.root}/calendar.db
[default]
default_calendar = outlook_personal
[locale]
local_timezone = Europe/Amsterdam
default_timezone = Europe/Amsterdam
longdatetimeformat = %Y-%m-%d %a %H:%M
datetimeformat = %Y-%m-%d %a %H:%M
longdateformat = %Y-%m-%d %a
dateformat = %Y-%m-%d %a
timeformat = %H:%M
""")
        env = dict(os.environ, HOME=str(self.root), XDG_CONFIG_HOME=str(self.root/'config'), XDG_STATE_HOME=str(self.root/'state'), XDG_DATA_HOME=str(self.root/'data'), XDG_CACHE_HOME=str(self.root/'cache'))
        projection = self.root/'projection.org'
        result = subprocess.run([sys.executable, str(SOURCE), 'export', 'outlook_personal', str(projection), '2028-01-03 Mon', '7d'], env=env, capture_output=True, text=True)
        self.assertNotEqual(0, result.returncode, 'The local CLI must reject an unconfigured host')
        marker = self.root/'config/calendar-bridge/server'
        marker.parent.mkdir()
        marker.write_text(socket.gethostname()+'\n')
        result = subprocess.run([sys.executable, str(SOURCE), 'export', 'outlook_personal', str(projection), '2028-01-03 Mon', '7d'], env=env, capture_output=True, text=True)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn(':BRIDGE_BASELINE:', projection.read_text())
        self.assertEqual(self.original, self.path.read_bytes())
        request = self.request()
        request_path = self.root/'request.json'
        request_path.write_text(json.dumps(request))
        for action in ['apply', 'verify']:
            result = subprocess.run([sys.executable, str(SOURCE), action, 'outlook_personal', str(request_path)], env=env, capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(request['request_id'], json.loads(result.stdout)['request_id'])

    def test_timed_creation_uses_utc_and_preserves_uid_on_retry(self):
        from icalendar import Calendar
        request = self.request(org='* New\n<2028-01-03 Mon 13:00-14:00>\n:PROPERTIES:\n:END:\n', action='new')
        result = self.service.apply(request)
        _, raw, parsed, _ = self.service.find(result['uid'])
        self.assertIn(b'DTSTART:20280103T120000Z', raw)
        self.assertEqual(1, len(parsed.walk('VEVENT')))
        self.assertRegex(raw.decode(), r'DTSTAMP:\d{8}T\d{6}Z')

    def test_server_metadata_rewrite_does_not_repeat_or_hide_an_edit(self):
        request = self.request()
        self.service.apply(request)
        from icalendar import Calendar
        parsed = Calendar.from_ical(self.path.read_bytes())
        event = parsed.walk('VEVENT')[0]
        from datetime import datetime, timezone
        event.pop('DTSTAMP', None)
        event.add('DTSTAMP', datetime(2028,1,1,tzinfo=timezone.utc))
        rewritten = parsed.to_ical()
        self.path.write_bytes(rewritten)
        self.service.verify(request)
        self.service.apply(request)
        self.assertEqual(rewritten, self.path.read_bytes())

    def test_interrupted_calendar_publication_preserves_the_original_and_receipt(self):
        request = self.request()
        replace = bridge.os.replace
        def fail_calendar(source, target):
            if Path(target) == self.path:
                raise OSError('Synthetic failure before atomic calendar replacement')
            return replace(source, target)
        with patch.object(bridge.os, 'replace', side_effect=fail_calendar):
            with self.assertRaises(OSError):
                self.service.apply(request)
        self.assertEqual(self.original,self.path.read_bytes())
        receipt = self.service.request_path(request['request_id'])
        self.assertEqual('prepared',json.loads(receipt.read_text())['status'])
        self.assertEqual(0o600,receipt.stat().st_mode & 0o777)
        self.assertFalse(list(self.calendar.glob('.calendar-*')))

if __name__ == '__main__':
    unittest.main()
