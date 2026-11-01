"""Real local bridge + real vdirsyncer filesystem transport. No Outlook access."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import unittest
import uuid

SOURCE = Path(__file__).resolve().parents[2]

class IntegrationTests(unittest.TestCase):
    def test_explicit_requests_and_read_only_exports_end_to_end(self):
        with tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR')) as temporary:
            home = Path(temporary)
            scripts = home/'dotfiles-linux/bin'
            scripts.mkdir(parents=True)
            (home/'dotfiles-linux/lib').mkdir()
            for name in ['calsync','calendar-submit','calendar-bridge-local']:
                shutil.copy2(SOURCE/'bin'/name, scripts/name)
            shutil.copy2(SOURCE/'lib/calendar_bridge.py', home/'dotfiles-linux/lib/calendar_bridge.py')
            launcher = home/'.local/share/pipx/venvs/khalorg/bin/python'
            launcher.parent.mkdir(parents=True)
            launcher.write_text('#!/bin/sh\nexec '+sys.executable+' "$@"\n')
            launcher.chmod(0o700)
            for name in ['.config/khal','.config/vdirsyncer','.config/calendar-bridge','.config/davmail','dropbox/generated','local','remote','fakebin']:
                (home/name).mkdir(parents=True, exist_ok=True)
            (home/'.config/calendar-bridge/server').write_text(socket.gethostname()+'\n')
            (home/'.config/khal/config').write_text(f'''[calendars]
[[outlook_personal]]
path = {home}/local
type = calendar
[sqlite]
path = {home}/calendar.db
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
''')
            (home/'.config/vdirsyncer/config').write_text(f'''[general]
status_path = "{home}/vdir-status"
[pair outlook_personal]
a = "local"
b = "remote"
collections = null
conflict_resolution = "b wins"
[storage local]
type = "filesystem"
path = "{home}/local"
fileext = ".ics"
[storage remote]
type = "filesystem"
path = "{home}/remote"
fileext = ".ics"
''')
            with socket.socket() as listener:
                listener.bind(('127.0.0.1',0))
                port = listener.getsockname()[1]
            config = home/'.config/davmail/davmail.personal.properties'
            config.write_text(f'davmail.caldavPort={port}\n')
            # Fake only the unused gateway and internet ping. Calendar sync itself
            # uses the real vdirsyncer executable against two isolated directories.
            (home/'fakebin/ping').write_text('#!/bin/sh\nexit 0\n')
            (home/'fakebin/pgrep').write_text('#!/bin/sh\nexit 1\n')
            (home/'fakebin/davmail').write_text('''#!/usr/bin/python3
import socket, sys
p=int(open(sys.argv[1]).read().strip().split('=')[1])
s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',p)); s.listen()
while True:
    c,_=s.accept(); c.close()
''')
            for path in (home/'fakebin').iterdir(): path.chmod(0o700)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home/'.config'), XDG_STATE_HOME=str(home/'state'), XDG_DATA_HOME=str(home/'data'), XDG_CACHE_HOME=str(home/'cache'), PATH=str(scripts)+os.pathsep+str(home/'fakebin')+os.pathsep+os.environ['PATH'])
            env.pop('VDIRSYNCER_CONFIG',None)
            initial = b'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Synthetic//EN\r\nBEGIN:VEVENT\r\nUID:existing@synthetic.invalid\r\nDTSTAMP:20260101T000000Z\r\nDTSTART:20280103T100000Z\r\nDTEND:20280103T110000Z\r\nSUMMARY:Original\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n'
            (home/'remote/event.ics').write_bytes(initial)
            discovered = subprocess.run(['/usr/bin/vdirsyncer','discover','outlook_personal'], env=env, input='y\n', capture_output=True, text=True, timeout=30)
            self.assertEqual(0, discovered.returncode, discovered.stderr)
            # Exercise calsync's normal exporter using the same bounded server path.
            projection = home/'dropbox/generated/outlook_personal.org'
            command = [str(scripts/'calsync'), '--verbose', str(config), 'outlook_personal', str(projection), '2028-01-03 Mon', '7d']
            def cycle():
                result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)
                self.assertEqual(0, result.returncode, result.stderr)
            cycle()
            before = {p.name:p.read_bytes() for p in (home/'remote').glob('*.ics')}
            projection.write_bytes(b'* Truncated\n<2028-01-03 Mon 11:00>\n')
            cycle()
            self.assertEqual(before, {p.name:p.read_bytes() for p in (home/'remote').glob('*.ics')})
            text = projection.read_text().replace('* Original','* Updated')
            request = dict(version=1, action='edit', calendar='outlook_personal', request_id=str(uuid.uuid4()), org=text)
            def submit(value):
                return subprocess.run([str(scripts/'calendar-submit')], input=json.dumps(value), env=env, text=True, capture_output=True, timeout=30)
            result = submit(request)
            self.assertEqual(0, result.returncode, result.stderr)
            response = json.loads(result.stdout)
            self.assertEqual('confirmed',response['status'])
            self.assertEqual('existing@synthetic.invalid',response['uid'])
            remote_bytes = b''.join(p.read_bytes() for p in (home/'remote').glob('*.ics'))
            self.assertIn(b'SUMMARY:Updated',remote_bytes)
            # A different edit with the old baseline must preserve the remote event.
            stale = request | {'request_id':str(uuid.uuid4()), 'org':text.replace('* Updated','* Stale')}
            result = submit(stale)
            self.assertNotEqual(0,result.returncode)
            self.assertEqual(remote_bytes,b''.join(p.read_bytes() for p in (home/'remote').glob('*.ics')))
            # Replaying the successful request is safe and creates no new event.
            result = submit(request)
            self.assertEqual(0,result.returncode,result.stderr)
            self.assertEqual(1,len(list((home/'remote').glob('*.ics'))))
            self.assertTrue(list((home/'state/calendar-bridge/requests').glob('*.json')))
            new = dict(version=1, action='new', calendar='outlook_personal', request_id=str(uuid.uuid4()), org='* All day\n<2028-01-04 Tue>\n:PROPERTIES:\n:CALENDAR: outlook_personal\n:END:\n')
            result = submit(new)
            self.assertEqual(0,result.returncode,result.stderr)
            created_uid = json.loads(result.stdout)['uid']
            result = submit(new)
            self.assertEqual(0,result.returncode,result.stderr)
            self.assertEqual(2,len(list((home/'remote').glob('*.ics'))))
            cycle()
            import re
            event_org = next(item for item in re.findall(r'^\* .*?(?=^\* |\Z)',projection.read_text(),re.M|re.S) if created_uid in item)
            all_day_edit = dict(version=1,action='edit',calendar='outlook_personal',request_id=str(uuid.uuid4()),org=event_org.replace('* All day','* All day updated'))
            result = submit(all_day_edit)
            self.assertEqual(0,result.returncode,result.stderr)
            from icalendar import Calendar
            from datetime import date
            event = next(event for file in (home/'remote').glob('*.ics') for event in Calendar.from_ical(file.read_bytes()).walk('VEVENT') if str(event['UID']) == created_uid)
            self.assertEqual(date(2028,1,4),event.decoded('DTSTART'))
            self.assertEqual(date(2028,1,5),event.decoded('DTEND'))
            cycle()
            race_org = next(item for item in re.findall(r'^\* .*?(?=^\* |\Z)',projection.read_text(),re.M|re.S) if 'existing@synthetic.invalid' in item)
            racing = dict(version=1,action='edit',calendar='outlook_personal',request_id=str(uuid.uuid4()),org=race_org.replace('* Updated','* Requested race'))
            # Change the real filesystem remote after local application, before
            # the real vdirsyncer push. No API or success response is fabricated.
            (home/'fakebin/vdirsyncer').write_text('''#!/usr/bin/python3
import os, pathlib, sys
home=pathlib.Path(os.environ['HOME'])
if any(b'SUMMARY:Requested race' in p.read_bytes() for p in (home/'local').glob('*.ics')):
    for p in (home/'remote').glob('*.ics'):
        raw=p.read_bytes()
        if b'UID:existing@synthetic.invalid' in raw:
            p.write_bytes(raw.replace(b'SUMMARY:Updated',b'SUMMARY:Remote race'))
os.execv('/usr/bin/vdirsyncer',['vdirsyncer']+sys.argv[1:])
''')
            (home/'fakebin/vdirsyncer').chmod(0o700)
            result = submit(racing)
            self.assertNotEqual(0,result.returncode)
            self.assertIn('verification failed', result.stderr)
            self.assertIn(b'SUMMARY:Remote race', b''.join(p.read_bytes() for p in (home/'remote').glob('*.ics')))
            pending = home/'state/calendar-bridge/requests'/(racing['request_id']+'.json')
            self.assertEqual(racing,json.loads(pending.read_text())['request'])



if __name__ == '__main__':
    unittest.main()
