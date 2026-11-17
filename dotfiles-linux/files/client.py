#!/usr/bin/env python3
"""FreeFileSync client for the private ftpu Files share. No deletion propagation."""
import argparse
import base64
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET


def locations():
    home = Path.home()
    config = Path(os.environ.get('XDG_CONFIG_HOME', home / '.config')) / 'ftpu-files'
    state = Path(os.environ.get('XDG_STATE_HOME', home / '.local/state')) / 'ftpu-files'
    return config, state


def private_directory(path):
    if path.is_symlink():
        raise ValueError('Private configuration directory must not be a symlink.')
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.chmod(0o700)


def validate(cfg):
    if not isinstance(cfg, dict) or set(cfg) != {'host', 'port', 'username', 'remote', 'local', 'password_entry'}:
        raise ValueError('Unexpected configuration fields. Run ftpu-files configure.')
    if not isinstance(cfg['host'], str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]*', cfg['host']):
        raise ValueError('Use the Pi MagicDNS name or its IPv4 address without a URL or options.')
    if type(cfg['port']) is not int or not 1 <= cfg['port'] <= 65535:
        raise ValueError('Invalid SFTP port.')
    if cfg['username'] != 'ftpu' or cfg['remote'] != '/drive/Files':
        raise ValueError('Only ftpu and /drive/Files are supported.')
    if not isinstance(cfg['password_entry'], str) or not cfg['password_entry'].strip():
        raise ValueError('A Bitwarden password item is required.')
    if not isinstance(cfg['local'], str):
        raise ValueError('Local folder must be a path.')
    local = Path(cfg['local']).expanduser()
    if not local.is_absolute() or local == Path('/') or local == Path.home():
        raise ValueError('Use a dedicated absolute local folder, normally ~/Files.')
    if any(c in str(local) for c in ('\n', '\r', '%')):
        raise ValueError('Local folder contains unsupported FreeFileSync macros or newlines.')
    cfg['local'] = str(local)
    return cfg


def load_config(path):
    mode = path.stat().st_mode
    if path.is_symlink() or not stat.S_ISREG(mode) or mode & 0o077:
        raise ValueError('Configuration must be a private regular file (chmod 600).')
    return validate(json.loads(path.read_text()))


def configuration(cfg, log_dir, batch=False, password=None):
    """XML format 23: database-based changes with both delete directions disabled."""
    root = ET.Element('FreeFileSync', XmlType='BATCH' if batch else 'GUI', XmlFormat='23')
    ET.SubElement(root, 'Notes').text = 'ftpu Files: deletion propagation OFF; resolve conflicts manually.'
    compare = ET.SubElement(root, 'Compare')
    ET.SubElement(compare, 'Variant').text = 'TimeAndSize'
    ET.SubElement(compare, 'Symlinks').text = 'Exclude'
    ET.SubElement(compare, 'IgnoreTimeShift')
    sync = ET.SubElement(root, 'Synchronize')
    changes = ET.SubElement(sync, 'Changes')
    ET.SubElement(changes, 'Left', Create='right', Update='right', Delete='none')
    ET.SubElement(changes, 'Right', Create='left', Update='left', Delete='none')
    # Preserve overwritten versions as well as the Pi's independent periodic history.
    ET.SubElement(sync, 'DeletionPolicy').text = 'Versioning'
    ET.SubElement(sync, 'VersioningFolder', Style='TimeStamp-Folder').text = str(log_dir.parent / 'versions')
    filters = ET.SubElement(root, 'Filter')
    ET.SubElement(ET.SubElement(filters, 'Include'), 'Item').text = '*'
    exclude = ET.SubElement(filters, 'Exclude')
    for pattern in ('/Generated/', '*.ffs_db', '*.ffs_lock', '*.ffs_tmp', '.stfolder/', '.stversions/'):
        ET.SubElement(exclude, 'Item').text = pattern
    ET.SubElement(filters, 'SizeMin', Unit='None').text = '0'
    ET.SubElement(filters, 'SizeMax', Unit='None').text = '0'
    ET.SubElement(filters, 'TimeSpan', Type='None').text = '0'
    pair = ET.SubElement(ET.SubElement(root, 'FolderPairs'), 'Pair')
    ET.SubElement(pair, 'Left').text = cfg['local']
    auth = '|pwprompt' if password is None else '|pass64=' + base64.b64encode(password.encode()).decode()
    ET.SubElement(pair, 'Right').text = (
        f"sftp://{cfg['username']}@{cfg['host']}:{cfg['port']}{cfg['remote']}{auth}")
    ET.SubElement(root, 'Errors', Ignore='true' if batch else 'false', Retry='0', Delay='5')
    ET.SubElement(root, 'PostSyncCommand', Condition='Completion')
    ET.SubElement(root, 'LogFolder').text = str(log_dir)
    ET.SubElement(root, 'EmailNotification', Condition='Always')
    ET.SubElement(root, 'GridViewType').text = 'Action'
    if batch:
        options = ET.SubElement(root, 'Batch')
        ET.SubElement(options, 'ProgressDialog', Minimized='true', AutoClose='true')
        ET.SubElement(options, 'ErrorDialog').text = 'Cancel'
        ET.SubElement(options, 'PostSyncAction').text = 'None'
    ET.indent(root)
    return ET.tostring(root, encoding='utf-8', xml_declaration=True)


def configure(args, config_dir):
    path = config_dir / 'config.json'
    if path.exists():
        raise ValueError('Configuration already exists. Edit the private config.json to change the endpoint.')
    host = args.host or input('Pi MagicDNS name: ').strip()
    entry = args.password_entry or input('Existing Bitwarden item name or ID for the ftpu password: ').strip()
    cfg = validate(dict(host=host, port=2222, username='ftpu', remote='/drive/Files',
                        local=str(Path(args.local).expanduser().absolute()), password_entry=entry))
    private_directory(config_dir)
    with open(path, 'x', opener=lambda p, f: os.open(p, f, 0o600)) as stream:
        json.dump(cfg, stream, indent=2)
        stream.write('\n')
    print('Private configuration saved. Run ftpu-files preview before the first sync.')


def executable():
    binary = shutil.which('FreeFileSync') or shutil.which('freefilesync')
    if not binary:
        raise ValueError('Install FreeFileSync through the Arch layer first.')
    return binary


def session_start():
    variables = [name for name in ('DISPLAY', 'WAYLAND_DISPLAY', 'XAUTHORITY', 'PATH') if os.environ.get(name)]
    if not variables:
        raise ValueError('This command needs a desktop session.')
    subprocess.run(['systemctl', '--user', 'import-environment', *variables], check=True)
    subprocess.run(['systemctl', '--user', 'start', 'ftpu-files-session.target'], check=True)


def run_client(cfg, state, batch):
    if not (os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY')):
        raise ValueError('FreeFileSync needs a desktop session, including for batch jobs.')
    binary = executable()
    if not shutil.which('tailscale'):
        raise ValueError('Install Tailscale first.')
    status = subprocess.run(['tailscale', 'status', '--json'], capture_output=True, text=True, timeout=15)
    if status.returncode or json.loads(status.stdout).get('BackendState') != 'Running':
        raise ValueError('Tailscale is offline. No synchronization started.')
    local = Path(cfg['local'])
    if not local.is_dir() or local.is_symlink():
        raise ValueError('Create the dedicated local folder first. Symlink roots are not supported.')
    private_directory(state)
    logs = state / 'logs'
    private_directory(logs)
    with (state / 'client.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError('Another ftpu-files process is active.') from None
        password = None
        if batch:
            if not shutil.which('rbw'):
                raise ValueError('Install rbw and unlock the vault first.')
            secret = subprocess.run(['rbw', 'get', '--', cfg['password_entry']],
                                    capture_output=True, text=True, timeout=30)
            if secret.returncode or not secret.stdout.rstrip('\n'):
                raise ValueError('Cannot read the password. Unlock rbw in the desktop session first.')
            password = secret.stdout.rstrip('\n')
        # Credentials stay in a mode-600 temporary file, never argv or the public template.
        # Prefer the desktop's tmpfs runtime directory over persistent state.
        with tempfile.TemporaryDirectory(prefix='ftpu-files-', dir=os.environ.get('XDG_RUNTIME_DIR')) as directory:
            job = Path(directory) / ('Files.ffs_batch' if batch else 'Files.ffs_gui')
            with open(job, 'xb', opener=lambda p, f: os.open(p, f, 0o600)) as stream:
                stream.write(configuration(cfg, logs, batch, password))
            result = subprocess.run([binary, str(job)])
        if batch and result.returncode == 0:
            (state / 'last-success').touch(mode=0o600)
        return result.returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    setup = commands.add_parser('configure', help='Save endpoint and vault item, without a password')
    setup.add_argument('--host')
    setup.add_argument('--password-entry')
    setup.add_argument('--local', default=str(Path.home() / 'Files'))
    for command in ('preview', 'sync', 'enable', 'disable', 'status', 'session-start'):
        commands.add_parser(command)
    args = parser.parse_args()
    config_dir, state = locations()
    if args.command == 'session-start':
        session_start()
        return 0
    if args.command == 'configure':
        configure(args, config_dir)
        return 0
    if args.command in ('disable', 'status'):
        if args.command == 'disable' and os.environ.get('WSL_DISTRO_NAME'):
            subprocess.run(['systemctl', '--user', 'disable', 'ftpu-files-session.target'], check=True)
        action = ['disable', '--now'] if args.command == 'disable' else ['status']
        return subprocess.run(['systemctl', '--user', *action, 'ftpu-files.timer']).returncode
    cfg = load_config(config_dir / 'config.json')
    if args.command == 'enable':
        if not (state / 'last-success').exists():
            raise ValueError('Run a successful ftpu-files sync before enabling its timer.')
        session_start()
        if os.environ.get('WSL_DISTRO_NAME'):
            subprocess.run(['systemctl', '--user', 'enable', 'ftpu-files-session.target'], check=True)
        return subprocess.run(['systemctl', '--user', 'enable', '--now', 'ftpu-files.timer']).returncode
    return run_client(cfg, state, args.command == 'sync')


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f'ftpu-files: {error}', file=sys.stderr)
        sys.exit(2)
