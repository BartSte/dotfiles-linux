import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import uuid

SOURCE = Path(__file__).resolve().parents[2]/'bin/calendar-submit'

class SubmitTests(unittest.TestCase):
    def test_transport_validates_request_and_confirms_only_success(self):
        with tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR')) as temporary:
            root = Path(temporary)
            shutil.copy2(SOURCE, root/'calendar-submit')
            fake = root/'calsync'
            fake.write_text('''#!/usr/bin/env python3
import sys, json, pathlib, os
p = pathlib.Path(sys.argv[sys.argv.index('--request')+1])
r = json.loads(p.read_text())
pathlib.Path(os.environ['TEST_REQUEST']).write_text(json.dumps(r))
if os.environ.get('FAIL_STAGE'):
    print('Remote sync failed', file=sys.stderr)
    sys.exit(7)
print(json.dumps(dict(status='confirmed_local', uid='synthetic', baseline='a'*64, calendar=r['calendar'], request_id=r['request_id'])))
''')
            fake.chmod(0o700)
            env = dict(os.environ, HOME=str(root), XDG_STATE_HOME=str(root/'state'), TEST_REQUEST=str(root/'seen.json'))
            request = dict(version=1, action='new', calendar='outlook_personal', request_id=str(uuid.uuid4()), org='* Literal $(touch BAD) `id` $HOME')
            def run(data, extra=None):
                return subprocess.run([str(root/'calendar-submit')], input=json.dumps(data), env=env | (extra or {}), text=True, capture_output=True)
            rejected = run(request | {'action': 'delete'})
            self.assertNotEqual(0, rejected.returncode)
            self.assertFalse((root/'seen.json').exists())
            failed = run(request, {'FAIL_STAGE': '1'})
            self.assertNotEqual(0, failed.returncode)
            self.assertNotIn('"status": "confirmed"', failed.stdout)
            result = run(request)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual('confirmed', json.loads(result.stdout)['status'])
            self.assertEqual(request, json.loads((root/'seen.json').read_text()))
            self.assertFalse(list((root/'state').rglob('request-*.json')))
            self.assertFalse((root/'BAD').exists())

if __name__ == '__main__':
    unittest.main()
