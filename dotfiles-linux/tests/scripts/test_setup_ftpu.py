#!/usr/bin/env python3
"""Unprivileged regression tests. No real accounts, mounts or services are changed."""
import os
import json
import runpy
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / 'scripts/setup-ftpu'
SUPPORT = runpy.run_path(str(SCRIPT.with_name('setup-ftpu-support.py')))


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='ftpu-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.env = dict(os.environ, TEST_ROOT=str(self.root))

    def bash(self, code, ok=True):
        result = subprocess.run(
            ['bash', '-c', f'source {shlex.quote(str(SCRIPT))}\n{code}'],
            env=self.env, text=True, capture_output=True,
        )
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertNotIn('Done.', result.stdout)
        return result

    def test_arguments(self):
        self.bash('parse_args --dry-run --allow-from 10.0.0.0/24 /dev/test; '
                  '[[ $DRY_RUN == true && $ALLOW_FROM == 10.0.0.0/24 && $DRIVE == /dev/test ]]')
        for args in ['', '--wrong /dev/test', '/dev/a /dev/b', '--allow-from',
                     '--allow-from 192.168.1.20/24 /dev/test',
                     '--allow-from ::/0 /dev/test', '--allow-from 0.0.0.0/0 /dev/test',
                     '--allow-from "bad;command" /dev/test', '--tailscale-phone',
                     '--tailscale-phone phone --lan-only /dev/test']:
            with self.subTest(args=args):
                self.bash('parse_args ' + args, ok=False)

    def test_help_needs_no_root(self):
        result = subprocess.run([str(SCRIPT), '--help'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn('--dry-run', result.stdout)

    def test_no_device_or_regular_file(self):
        self.bash('DRIVE=/nonexistent-ftpu-test; check_device', ok=False)
        self.bash('DRIVE="$TEST_ROOT"; check_device', ok=False)

    def test_symlinks_and_covered_data(self):
        (self.root / 'real').mkdir()
        (self.root / 'link').symlink_to(self.root / 'real')
        self.bash('safe_path "$TEST_ROOT/link/child"', ok=False)
        self.bash('assert_empty_directory "$TEST_ROOT/real"')
        (self.root / 'real/precious-photo').write_text('keep')
        self.bash('assert_empty_directory "$TEST_ROOT/real"', ok=False)
        self.assertEqual((self.root / 'real/precious-photo').read_text(), 'keep')

    def test_render_repeat_and_network_update(self):
        (self.root / 'original').write_text('# keep\n/dev/root / ext4 defaults 0 1\n')
        self.bash('''
UUID=1234; DRIVE=/dev/test
fstab_block 1001 1001 > "$TEST_ROOT/block"
render_config fstab "$TEST_ROOT/original" "$TEST_ROOT/block" "$TEST_ROOT/once"
render_config fstab "$TEST_ROOT/once" "$TEST_ROOT/block" "$TEST_ROOT/twice"
cmp "$TEST_ROOT/once" "$TEST_ROOT/twice"
ssh_block > "$TEST_ROOT/sshblock"
render_config ssh "$TEST_ROOT/original" "$TEST_ROOT/sshblock" "$TEST_ROOT/ssh"
ALLOW_FROM=10.0.0.0/24
ssh_block > "$TEST_ROOT/sshblock"
render_config ssh "$TEST_ROOT/ssh" "$TEST_ROOT/sshblock" "$TEST_ROOT/sshnew"
''')
        text = (self.root / 'twice').read_text()
        self.assertEqual(text.count('# BEGIN setup-ftpu'), 1)
        self.assertIn('UUID=1234', text)
        self.assertIn('x-systemd.requires=/my-fdd-drive', text)
        ssh = (self.root / 'sshnew').read_text()
        self.assertIn('AllowUsers ftpu@10.0.0.0/24', ssh)
        self.assertNotIn('192.168.1.0/24', ssh)

    def test_configuration_conflicts(self):
        cases = [
            ('fstab', '/dev/test /elsewhere ntfs defaults 0 0\n'),
            ('fstab', 'UUID=1234 /elsewhere ntfs defaults 0 0\n'),
            ('fstab', '/dev/other /my-fdd-drive ntfs defaults 0 0\n'),
            ('fstab', '/my-fdd-drive /home/ftpu/data none bind 0 0\n'),
            ('fstab', '/dev/other /home/ftpu/drive none bind 0 0\n'),
            ('ssh', 'Match User ftpu\n    ForceCommand something\n'),
            ('ssh', '# BEGIN setup-ftpu\n'),
            ('ssh', '# END setup-ftpu\n'),
            ('ssh', '# BEGIN setup-ftpu\n# END setup-ftpu\n# BEGIN setup-ftpu\n# END setup-ftpu\n'),
        ]
        (self.root / 'block').write_text('replacement\n')
        for kind, text in cases:
            with self.subTest(text=text):
                (self.root / 'original').write_text(text)
                self.bash(f'UUID=1234; DRIVE=/dev/test; render_config {kind} '
                          '"$TEST_ROOT/original" "$TEST_ROOT/block" "$TEST_ROOT/output"', ok=False)
                self.assertEqual((self.root / 'original').read_text(), text)

    def test_dry_run_never_calls_mutators(self):
        result = self.bash('''
check_environment() { UUID=1234; }
discover_phone() { :; }
preflight_config() { :; }
connection_details() { :; }
install() { die 'mutation reached'; }
apply_setup() { die 'mutation reached'; }
main --dry-run /dev/test
''')
        self.assertIn('No changes made', result.stdout)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_ssh_checks_reject_overrides_and_admin_changes(self):
        # Real sshd syntax and login behavior are exercised in the container test.
        common = '''
sshd() { :; }
SSHD_CONFIG=original
ssh_block | awk '{$1=tolower($1); print}' > "$TEST_ROOT/effective"
effective_ssh() {
    if [[ $2 == barts ]]; then echo 'port 22'; return; fi
    echo 'port 22'
    cat "$TEST_ROOT/effective"
}
'''
        self.bash(common + 'validate_ssh candidate')
        self.bash(common + '''
sed -i 's/disableforwarding yes/disableforwarding no/' "$TEST_ROOT/effective"
validate_ssh candidate
''', ok=False)
        self.bash(common + '''
effective_ssh() { printf 'port 22\ncustom %s\n' "$1"; }
validate_ssh candidate
''', ok=False)

    def test_wrong_bind_and_unsafe_mounts(self):
        self.bash('''
UUID=1234
mount_at() { case $2 in UUID) echo 1234;; FSROOT) echo /;; esac; }
verify_bind
''', ok=False)
        self.bash('''
UUID=1234
mount_at() { case $2 in UUID) echo 1234;; FSROOT) echo /PhoneBackups;; esac; }
verify_drive_bind
''', ok=False)
        self.bash('''
UUID=1234
mount_at() {
    case $2 in UUID) echo 1234;; FSROOT) if [[ $1 == "$JAIL/drive" ]]; then echo /; else echo /PhoneBackups; fi;;
        FSTYPE) echo fuseblk;; OPTIONS) echo rw,nosuid,nodev;; esac
}
verify_mounts
''', ok=False)

    def test_atomic_replace(self):
        (self.root / 'old').write_text('old')
        (self.root / 'new').write_text('new')
        self.bash('atomic_replace "$TEST_ROOT/new" "$TEST_ROOT/old"')
        self.assertEqual((self.root / 'old').read_text(), 'new')
        self.bash('atomic_replace "$TEST_ROOT/missing" "$TEST_ROOT/old"', ok=False)
        self.assertEqual((self.root / 'old').read_text(), 'new')
        self.assertEqual(len(list(self.root.iterdir())), 2)

    def test_systemd_generates_mount_dependency_and_timeout(self):
        generator = Path('/usr/lib/systemd/system-generators/systemd-fstab-generator')
        if not generator.exists():
            self.skipTest('systemd fstab generator is unavailable')
        self.bash('''
UUID=1234
fstab_block 1001 1001 > "$TEST_ROOT/fstab"
mkdir "$TEST_ROOT/normal" "$TEST_ROOT/early" "$TEST_ROOT/late"
SYSTEMD_FSTAB="$TEST_ROOT/fstab" /usr/lib/systemd/system-generators/systemd-fstab-generator \
    "$TEST_ROOT/normal" "$TEST_ROOT/early" "$TEST_ROOT/late"
''')
        drive_unit = 'my\\x2dfdd\\x2ddrive.mount'
        bind = (self.root / 'normal/home-ftpu-data.mount').read_text()
        drive = (self.root / 'normal' / drive_unit).read_text()
        self.assertIn('Requires=' + drive_unit, bind)
        self.assertIn('After=' + drive_unit, bind)
        self.assertIn('What=/my-fdd-drive/PhoneBackups', bind)
        self.assertIn('What=/dev/disk/by-uuid/1234', drive)
        full_drive = (self.root / 'normal/home-ftpu-drive.mount').read_text()
        self.assertIn('Requires=' + drive_unit, full_drive)
        self.assertIn('After=' + drive_unit, full_drive)
        self.assertIn('What=/my-fdd-drive\n', full_drive)
        self.assertFalse((self.root / 'normal/local-fs.target.requires' / drive_unit).exists())
        timeout_files = list((self.root / 'normal').glob('*.device.d/*.conf'))
        self.assertTrue(timeout_files)
        self.assertTrue(any('10s' in file.read_text() for file in timeout_files))

    def test_failure_restores_configuration_and_locks_account(self):
        for failure in ['mount', 'fstab', 'ssh', 'password']:
            with self.subTest(failure=failure):
                (self.root / 'fstab').write_text('original-fstab')
                (self.root / 'sshd').write_text('original-sshd')
                (self.root / 'backup').mkdir(exist_ok=True)
                result = self.bash('''
FSTAB="$TEST_ROOT/fstab"; SSHD_CONFIG="$TEST_ROOT/sshd"
WORK="$TEST_ROOT/backup"
cp "$FSTAB" "$WORK/fstab.before"; cp "$SSHD_CONFIG" "$WORK/sshd.before"
usermod() { printf '%s\n' "$*" >> "$TEST_ROOT/account-actions"; }
systemctl() { :; }
sshd() { :; }
trap cleanup EXIT
ACCOUNT_TOUCHED=true
''' + ('''
FSTAB_CHANGED=true
printf changed > "$FSTAB"
''' if failure != 'mount' else '') + ('''
SSH_CHANGED=true
printf changed > "$SSHD_CONFIG"
''' if failure in ('ssh', 'password') else '') + 'false\necho "Done."', ok=False)
                self.assertIn('Recovery files:', result.stderr)
                self.assertEqual((self.root / 'fstab').read_text(), 'original-fstab')
                self.assertEqual((self.root / 'sshd').read_text(), 'original-sshd')
                self.assertIn('-L ftpu', (self.root / 'account-actions').read_text())

    def test_apply_stops_at_package_failure(self):
        self.bash('''
require_terminal() { :; }
dpkg-query() { return 1; }
apt-get() { return 17; }
useradd() { die 'account creation reached'; }
apply_setup
''', ok=False)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_apply_orchestration_repeat_and_failure(self):
        fixture = r'''
FSTAB="$TEST_ROOT/fstab"; SSHD_CONFIG="$TEST_ROOT/sshd"
STATE_DIR="$TEST_ROOT/state"; BACKUP_ROOT="$TEST_ROOT/backups"
SFTP_CONFIG="$TEST_ROOT/sftp"; SFTP_UNIT="$TEST_ROOT/sftp.service"
UFW_DIR="$TEST_ROOT/ufw"
DRIVE_MOUNT="$TEST_ROOT/drive"; JAIL="$TEST_ROOT/jail"
DRIVE=/dev/test; UUID=1234
mkdir -p "$STATE_DIR" "$BACKUP_ROOT"
[[ -e $FSTAB ]] || printf '# original fstab\n' > "$FSTAB"
[[ -e $SSHD_CONFIG ]] || printf '# original ssh\n' > "$SSHD_CONFIG"
[[ -e $TEST_ROOT/password ]] || echo P > "$TEST_ROOT/password"
record() { printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
require_terminal() { :; }
dpkg-query() { printf 'install ok installed'; }
sshd() { :; }
getent() { :; }
id() { case $1 in -u) echo 1001;; -g) echo 1001;; esac; }
passwd() { [[ $1 == -S ]] || die 'unexpected password reset'; printf 'ftpu %s\n' "$(cat "$TEST_ROOT/password")"; }
usermod() { record "usermod $*"; case $1 in -L) echo L;; -U) echo P;; esac > "$TEST_ROOT/password"; }
install() {
    local -a args=()
    while (($#)); do
        case $1 in -o|-g) shift 2;; *) args+=("$1"); shift;; esac
    done
    command install "${args[@]}"
}
runuser() { :; }
mountpoint() {
    if [[ $2 == "$DRIVE_MOUNT" ]]; then [[ -e $TEST_ROOT/drive-active ]];
    else [[ -e $TEST_ROOT/bind-active ]]; fi
}
mount() { record mount; [[ ${FAIL_AT:-} != mount ]] || return 11; touch "$TEST_ROOT/drive-active"; }
systemd-mount() { mount "$@"; }
mount_at() { case $2 in UUID) echo 1234;; FSTYPE) echo fuseblk;; OPTIONS) echo rw,nosuid,nodev,noexec;; esac; }
findmnt() { :; }
validate_ssh() { record validate; [[ ${FAIL_AT:-} != validate ]]; }
validate_sftp() { record validate-sftp; }
systemd-analyze() { :; }
configure_firewall() { record configure-firewall; [[ ${FAIL_AT:-} != firewall ]]; }
connection_details() { :; }
verify_covered_directory() { record covered-directory; }
verify_mounts() { record verify-mounts; }
systemctl() {
    record "systemctl $*"
    if [[ ${FAIL_AT:-} == reload && $1 == reload ]]; then return 12; fi
    if [[ ${FAIL_AT:-} == sftp-reload && $1 == reload && $2 == ftpu-sftp ]]; then return 13; fi
    if [[ $1 == start && $2 == *.mount ]]; then touch "$TEST_ROOT/bind-active"; fi
}
trap cleanup EXIT
apply_setup
'''
        first = self.bash(fixture)
        self.assertIn('Done.', first.stdout)
        before = (self.root / 'fstab').read_text(), (self.root / 'sshd').read_text()
        second = self.bash(fixture)
        self.assertIn('Done.', second.stdout)
        after = (self.root / 'fstab').read_text(), (self.root / 'sshd').read_text()
        self.assertEqual(before, after)
        self.assertEqual((self.root / 'password').read_text(), 'P\n')
        trace = (self.root / 'trace').read_text()
        self.assertIn('covered-directory', trace)
        self.assertEqual(trace.count('usermod -U ftpu'), 2)
        self.assertLess(trace.index('validate'), trace.index('systemctl reload ssh'))
        self.assertLess(trace.index('systemctl reload ssh'), trace.index('usermod -U ftpu'))
        before_sftp = (self.root / 'sftp').read_text(), (self.root / 'sftp.service').read_text()
        for failure in ('mount', 'validate', 'reload', 'sftp-reload', 'firewall'):
            with self.subTest(failure=failure):
                if failure == 'mount':
                    (self.root / 'drive-active').unlink()
                    (self.root / 'bind-active').unlink()
                self.bash(f'FAIL_AT={failure}\n' + fixture, ok=False)
                self.assertEqual(before, ((self.root / 'fstab').read_text(), (self.root / 'sshd').read_text()))
                self.assertEqual((self.root / 'password').read_text(), 'L\n')
                self.assertEqual(before_sftp, ((self.root / 'sftp').read_text(), (self.root / 'sftp.service').read_text()))
                (self.root / 'password').write_text('P\n')


    def test_drive_mount_is_owned_by_systemd(self):
        for load_state in ('loaded', 'not-found'):
            with self.subTest(load_state=load_state):
                self.bash('''
systemctl() {
    if [[ $1 == show ]]; then echo "$TEST_LOAD_STATE";
    else printf '%s\\n' "$*" > "$TEST_ROOT/systemctl"; fi
}
systemd-mount() { printf '%s\\n' "$*" > "$TEST_ROOT/systemd-mount"; }
mount() { die 'raw mount must never start the NTFS daemon'; }
DRIVE=/dev/test
''' + f'TEST_LOAD_STATE={load_state}\nmount_drive_managed 1001 1001')
                if load_state == 'loaded':
                    self.assertIn('start my\\x2dfdd\\x2ddrive.mount', (self.root / 'systemctl').read_text())
                else:
                    self.assertIn('--collect --automount=no --type=ntfs-3g',
                                  (self.root / 'systemd-mount').read_text())

    def test_phone_selection_and_saved_identity(self):
        select = SUPPORT['select_phone']
        old = {'ID': 'old-id', 'HostName': 'Old phone', 'DNSName': 'old.tail.ts.net.',
               'OS': 'android', 'Online': False, 'TailscaleIPs': ['100.100.100.100']}
        phone = {'ID': 'phone-id', 'HostName': 'Bart Phone', 'DNSName': 'bart-phone.tail.ts.net.',
                 'OS': 'android', 'Online': True,
                 'TailscaleIPs': ['100.100.100.101', 'fd7a:115c:a1e0::1234']}
        status = {'BackendState': 'Running', 'Self': {'DNSName': 'pi.tail.ts.net.',
                  'TailscaleIPs': ['100.100.100.1']}, 'Peer': {'old': old, 'phone': phone}}
        saved = select(status)
        self.assertEqual(saved['phone']['id'], 'phone-id')
        self.assertEqual(len(saved['phone']['ips']), 2)
        for name in ('Bart Phone', 'bart-phone', 'bart-phone.tail.ts.net.', 'phone-id',
                     '100.100.100.101', 'fd7a:115c:a1e0::1234'):
            self.assertEqual(select(status, name)['phone']['id'], 'phone-id')
        phone['Online'], old['Online'] = False, True
        self.assertEqual(select(status, saved=saved)['phone']['id'], 'phone-id')
        phone['Online'] = True
        with self.assertRaises(ValueError):
            select(status)
        del status['Peer']['phone']
        with self.assertRaises(ValueError):
            select(status, saved=saved)
        self.assertEqual(select(status)['phone']['id'], 'old-id')
        old['TailscaleIPs'] = ['192.168.1.42']
        with self.assertRaises(ValueError):
            select(status)
        status['BackendState'] = 'NeedsLogin'
        with self.assertRaises(ValueError):
            select(status)

    def test_exact_sources_and_lan_only(self):
        self.bash('''
PHONE_JSON='{"phone":{"ips":["100.100.100.101","fd7a:115c:a1e0::1234"]}}'
[[ $(allowed_users) == 'ftpu@192.168.1.0/24 ftpu@100.100.100.101 ftpu@fd7a:115c:a1e0::1234' ]]
LAN_ONLY=true
tailscale() { die 'Tailscale was reached in LAN-only mode'; }
discover_phone
[[ $(allowed_users) == 'ftpu@192.168.1.0/24' ]]
''')

    def test_firewall_changes_only_own_rules(self):
        plan = SUPPORT['firewall_plan']
        original = """Added user rules:
ufw allow 22/tcp
ufw allow from 100.100.100.100 to any port 2222 proto tcp comment 'setup-ftpu'
ufw allow from 10.0.0.0/8 to any port 2222 proto tcp comment 'admin-owned'
"""
        result = plan(original, ['192.168.1.0/24', '100.100.100.101'])
        self.assertEqual(len(result['remove']), 1)
        self.assertEqual(result['remove'][0][2], '100.100.100.100')
        self.assertEqual(len(result['add']), 2)
        rendered = '\n'.join('ufw ' + shlex.join(rule) for rule in result['add'])
        self.assertEqual(plan(rendered, ['192.168.1.0/24', '100.100.100.101']), {'add': [], 'remove': []})
        admin_rule = "ufw allow from 100.100.100.101 to any port 2222 proto tcp comment 'admin-owned'"
        self.assertEqual(plan(admin_rule, ['100.100.100.101']), {'add': [], 'remove': []})

    def test_firewall_execution_and_rollback(self):
        (self.root / 'bin').mkdir()
        (self.root / 'ufw').mkdir()
        (self.root / 'backup').mkdir()
        (self.root / 'ufw/user.rules').write_text('original IPv4')
        (self.root / 'ufw/user6.rules').write_text('original IPv6')
        mock = self.root / 'bin/ufw'
        mock.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
root = pathlib.Path(os.environ['TEST_ROOT'])
args = sys.argv[1:]
with (root / 'ufw-trace').open('a') as log:
    log.write(json.dumps(args) + '\\n')
if args == ['status']:
    print('Status: active')
elif args == ['show', 'added']:
    print("ufw allow from 100.100.100.100 to any port 2222 proto tcp comment 'setup-ftpu'")
elif args != ['reload']:
    (root / 'ufw/user.rules').write_text('changed IPv4')
    (root / 'ufw/user6.rules').write_text('changed IPv6')
''')
        mock.chmod(0o755)
        self.bash('''
export PATH="$TEST_ROOT/bin:$PATH"
UFW_DIR="$TEST_ROOT/ufw"; WORK="$TEST_ROOT/backup"
PHONE_JSON='{"phone":{"ips":["100.100.100.101","fd7a:115c:a1e0::1234"]}}'
trap cleanup EXIT
configure_firewall
false
''', ok=False)
        self.assertEqual((self.root / 'ufw/user.rules').read_text(), 'original IPv4')
        self.assertEqual((self.root / 'ufw/user6.rules').read_text(), 'original IPv6')
        trace = [json.loads(line) for line in (self.root / 'ufw-trace').read_text().splitlines()]
        self.assertEqual(sum(args[:3] == ['--force', 'delete', 'allow'] for args in trace), 1)
        self.assertEqual(sum(args[:1] == ['allow'] for args in trace), 3)
        self.assertEqual(trace[-1], ['reload'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
