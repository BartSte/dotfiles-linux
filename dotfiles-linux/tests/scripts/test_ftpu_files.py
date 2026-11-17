#!/usr/bin/env python3
"""Client safety checks using a fake desktop, vault, and FreeFileSync process."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('ftpu_client', ROOT / 'files/client.py')
CLIENT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CLIENT)


class ClientTests(unittest.TestCase):
    def test_session_uses_dependency_target_and_imports_executable_path(self):
        with patch.dict(os.environ, {'DISPLAY': ':0', 'PATH': '/fixture/bin'}), \
                patch.object(CLIENT.subprocess, 'run') as run:
            CLIENT.session_start()
        self.assertIn('PATH', run.call_args_list[0].args[0])
        self.assertEqual(run.call_args_list[1].args[0],
                         ['systemctl', '--user', 'start', 'ftpu-files-session.target'])

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ftpu files test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.local = self.root / 'Local Files'
        self.local.mkdir()
        self.cfg = dict(host='pi.example.ts.net', port=2222, username='ftpu',
                        remote='/drive/Files', local=str(self.local), password_entry='Private item')
        self.state = self.root / 'state'

    def test_xml_has_database_rules_no_delete_and_no_password_in_preview(self):
        root = ET.fromstring(CLIENT.configuration(self.cfg, self.state / 'logs'))
        self.assertEqual(root.attrib, dict(XmlType='GUI', XmlFormat='23'))
        self.assertIsNone(root.find('Synchronize/Differences'))
        for side, destination in [('Left', 'right'), ('Right', 'left')]:
            self.assertEqual(root.find(f'Synchronize/Changes/{side}').attrib,
                             dict(Create=destination, Update=destination, Delete='none'))
        self.assertEqual(root.findtext('FolderPairs/Pair/Left'), str(self.local))
        self.assertTrue(root.findtext('FolderPairs/Pair/Right').endswith('|pwprompt'))
        self.assertEqual(root.findtext('Synchronize/DeletionPolicy'), 'Versioning')
        self.assertEqual(root.find('Synchronize/VersioningFolder').get('Style'), 'TimeStamp-Folder')
        self.assertEqual(root.find('Compare/Symlinks').text, 'Exclude')
        self.assertIn('/Generated/', [n.text for n in root.findall('Filter/Exclude/Item')])

    def test_validate_rejects_option_injection_and_unsafe_roots(self):
        for field, value in [('host', 'pi|pass64=evil'), ('host', 'sftp://pi'),
                             ('port', True), ('port', 0), ('local', '/'),
                             ('local', str(Path.home())), ('local', '/tmp/%HOME%'),
                             ('local', None), ('remote', '/drive'), ('username', 'root'),
                             ('password_entry', '')]:
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                CLIENT.validate(dict(self.cfg, **{field: value}))
        with self.assertRaises(ValueError):
            CLIENT.validate(dict(self.cfg, deletion=True))
        for value in ('true', 1, None):
            with self.subTest(sync_deletions=value), self.assertRaises(ValueError):
                CLIENT.validate(dict(self.cfg, sync_deletions=value))

    def test_deletions_apply_both_directions_and_keep_versioning_outside_files(self):
        cfg = CLIENT.validate(dict(self.cfg, sync_deletions=True))
        root = ET.fromstring(CLIENT.configuration(cfg, self.state / 'logs', batch=True))
        self.assertEqual(root.find('Synchronize/Changes/Left').get('Delete'), 'right')
        self.assertEqual(root.find('Synchronize/Changes/Right').get('Delete'), 'left')
        self.assertEqual(root.findtext('Synchronize/DeletionPolicy'), 'Versioning')
        versions = Path(root.findtext('Synchronize/VersioningFolder'))
        self.assertFalse(versions.is_relative_to(self.local))

    def test_policy_changes_preserve_profile_and_do_not_reset_sync_history(self):
        config_dir = self.root / 'profile'
        CLIENT.private_directory(config_dir)
        database = self.local / '.sync.ffs_db'
        database.write_bytes(b'previous sync history')
        CLIENT.set_deletions(config_dir, self.state, self.cfg, True)
        saved = CLIENT.load_config(config_dir / 'config.json')
        self.assertEqual(saved, dict(self.cfg, sync_deletions=True))
        self.assertEqual((config_dir / 'config.json').stat().st_mode & 0o777, 0o600)
        CLIENT.set_deletions(config_dir, self.state, saved, False)
        self.assertFalse(CLIENT.load_config(config_dir / 'config.json')['sync_deletions'])
        self.assertEqual(database.read_bytes(), b'previous sync history')

    def test_policy_change_refuses_an_active_sync(self):
        CLIENT.private_directory(self.state)
        with (self.state / 'client.lock').open('a') as lock:
            CLIENT.fcntl.flock(lock, CLIENT.fcntl.LOCK_EX | CLIENT.fcntl.LOCK_NB)
            with self.assertRaisesRegex(ValueError, 'process is active'):
                CLIENT.set_deletions(self.root, self.state, self.cfg, True)
        self.assertFalse((self.root / 'config.json').exists())

    def test_enrollment_private_repeat_does_not_overwrite(self):
        args = type('Args', (), dict(host=self.cfg['host'], password_entry='Private item', local=str(self.local)))()
        path = self.root / 'config dir'
        CLIENT.configure(args, path)
        file = path / 'config.json'
        self.assertEqual(file.stat().st_mode & 0o777, 0o600)
        self.assertEqual(path.stat().st_mode & 0o777, 0o700)
        self.assertEqual(CLIENT.load_config(file), self.cfg)
        with self.assertRaises(ValueError):
            CLIENT.configure(args, path)
        self.assertEqual(json.loads(file.read_text()), self.cfg)
        file.chmod(0o644)
        with self.assertRaises(ValueError):
            CLIENT.load_config(file)

    def run_client(self, mode='sync', offline=False, exitcode=0, vault_locked=False):
        calls = []
        secret = 'fixture-only<& secret'

        def execute(args, **kwargs):
            calls.append(args)
            if args[0] == 'tailscale':
                return subprocess.CompletedProcess(args, 0, json.dumps({'BackendState': 'Stopped' if offline else 'Running'}))
            if args[0] == 'rbw':
                self.assertEqual(args, ['rbw', 'get', '--', 'Private item'])
                return subprocess.CompletedProcess(args, 1 if vault_locked else 0, secret + '\n')
            if mode == 'sync':
                self.assertEqual(args[:-1], ['/fixture/tool', '--auto-servernum', '/fixture/FreeFileSync'])
                self.assertEqual(kwargs['env']['GDK_BACKEND'], 'x11')
                self.assertNotIn('WAYLAND_DISPLAY', kwargs['env'])
            else:
                self.assertEqual(args[0], '/fixture/FreeFileSync')
            job = Path(args[-1])
            self.assertEqual(job.stat().st_mode & 0o777, 0o600)
            self.assertEqual(job.parent.stat().st_mode & 0o777, 0o700)
            root = ET.parse(job).getroot()
            right = root.findtext('FolderPairs/Pair/Right')
            self.assertNotIn(secret, str(args))
            self.assertEqual(root.get('XmlType'), 'BATCH' if mode == 'sync' else 'GUI')
            if mode == 'sync':
                self.assertIn('|pass64=', right)
                self.assertEqual(root.find('Batch/ErrorDialog').text, 'Cancel')
            else:
                self.assertIn('|pwprompt', right)
            return subprocess.CompletedProcess(args, exitcode)

        with patch.dict(os.environ, {'DISPLAY': ':fixture'}), \
                patch.object(CLIENT.shutil, 'which', return_value='/fixture/tool'), \
                patch.object(CLIENT, 'executable', return_value='/fixture/FreeFileSync'), \
                patch.object(CLIENT.subprocess, 'run', side_effect=execute):
            result = CLIENT.run_client(self.cfg, self.state, mode == 'sync')
        return result, calls

    def test_batch_credentials_stay_out_of_argv_and_temporary_profile_is_removed(self):
        result, calls = self.run_client()
        self.assertEqual(result, 0)
        self.assertEqual(len(calls), 3)
        self.assertTrue((self.state / 'last-success').exists())
        self.assertFalse(Path(calls[-1][-1]).exists())

    def test_preview_never_fetches_vault_password(self):
        _, calls = self.run_client('preview')
        self.assertFalse(any(args[0] == 'rbw' for args in calls))
        self.assertFalse((self.state / 'last-success').exists())
        self.assertFalse(Path(calls[-1][-1]).exists())

    def test_offline_and_locked_vault_fail_before_sync(self):
        for options in (dict(offline=True), dict(vault_locked=True)):
            with self.subTest(options=options), self.assertRaises(ValueError):
                self.run_client(**options)
        self.assertFalse((self.state / 'last-success').exists())
        self.assertEqual(list(self.state.glob('run-*')), [])

    def test_warning_does_not_authorize_timer_and_temporary_profile_is_removed(self):
        result, calls = self.run_client(exitcode=1)
        self.assertEqual(result, 1)
        self.assertFalse((self.state / 'last-success').exists())
        self.assertFalse(Path(calls[-1][-1]).exists())

    def test_missing_desktop_or_local_folder_never_starts_sync(self):
        with patch.dict(os.environ, {}, clear=True), self.assertRaises(ValueError):
            CLIENT.run_client(self.cfg, self.state, True)
        self.local.rmdir()
        with self.assertRaises(ValueError):
            self.run_client()

    def test_nonblocking_lock_prevents_second_process(self):
        CLIENT.private_directory(self.state)
        with (self.state / 'client.lock').open('a') as lock:
            CLIENT.fcntl.flock(lock, CLIENT.fcntl.LOCK_EX | CLIENT.fcntl.LOCK_NB)
            with self.assertRaises(ValueError):
                self.run_client()

    def test_launch_failure_removes_the_profile(self):
        jobs = []

        def execute(args, **kwargs):
            if args[0] == 'tailscale':
                return subprocess.CompletedProcess(args, 0, '{"BackendState":"Running"}')
            if args[0] == 'rbw':
                return subprocess.CompletedProcess(args, 0, 'fixture-password\n')
            jobs.append(Path(args[-1]))
            self.assertTrue(jobs[-1].exists())
            raise OSError('fixture launch failure')

        with patch.dict(os.environ, {'DISPLAY': ':fixture'}), \
                patch.object(CLIENT.shutil, 'which', return_value='/fixture/tool'), \
                patch.object(CLIENT, 'executable', return_value='/fixture/FreeFileSync'), \
                patch.object(CLIENT.subprocess, 'run', side_effect=execute), self.assertRaises(OSError):
            CLIENT.run_client(self.cfg, self.state, True)
        self.assertEqual(len(jobs), 1)
        self.assertFalse(jobs[0].exists())

    def test_missing_virtual_display_never_falls_back_to_a_visible_sync(self):
        with patch.dict(os.environ, {'DISPLAY': ':fixture'}), \
                patch.object(CLIENT, 'executable', return_value='/fixture/FreeFileSync'), \
                patch.object(CLIENT.shutil, 'which', side_effect=lambda name: None if name == 'xvfb-run' else '/fixture/tool'), \
                patch.object(CLIENT.subprocess, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'Silent sync needs'):
                CLIENT.run_client(self.cfg, self.state, True)
        run.assert_not_called()

    def test_enable_needs_successful_batch_before_systemd(self):
        config_dir = self.root / 'config'
        CLIENT.private_directory(config_dir)
        cfg = config_dir / 'config.json'
        cfg.write_text(json.dumps(self.cfg))
        cfg.chmod(0o600)
        with patch.object(CLIENT, 'locations', return_value=(config_dir, self.state)), \
                patch.object(CLIENT.subprocess, 'run') as run, \
                patch.object(CLIENT.sys, 'argv', ['ftpu-files', 'enable']), self.assertRaises(ValueError):
            CLIENT.main()
        run.assert_not_called()

    def test_install_is_repeatable_and_never_enables_or_starts_sync(self):
        home = self.root / 'home with spaces'
        home.mkdir()
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'), CI='true')
        for _ in range(2):
            subprocess.run([str(ROOT / 'files/main')], env=env, check=True, capture_output=True)
        units = home / '.config/systemd/user'
        self.assertTrue((units / 'ftpu-files.timer').is_symlink())
        self.assertFalse((units / 'graphical-session.target.wants').exists())
        self.assertFalse((home / 'Files').exists())
        self.assertFalse((home / '.config/ftpu-files/config.json').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
