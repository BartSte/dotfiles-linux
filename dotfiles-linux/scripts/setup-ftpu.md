# Restricted phone backups over SFTP

`setup-ftpu` configures the `ftpu` account to access only `PhoneBackups` on an NTFS drive. It uses password authentication and allows connections from `192.168.1.0/24` by default. Other SSH accounts, including `barts`, keep their existing settings.

The script supports Debian-based Raspberry Pi systems with an existing OpenSSH configuration and a `barts` administrative account. Python 3 and the standard Debian account, mount, and systemd tools must already be available. It installs missing `openssh-server` and `ntfs-3g` packages without upgrading the rest of the system.

## Before setup

Keep another copy of important photos. The phone can overwrite and delete files in its backup folder; this setup does not provide version history or protection from drive failure.

Inspect the partition with `lsblk -f`. Do not format it. Unmount any desktop or other mounts of that partition before setup. Keep your current administrative SSH session open while applying changes.

Run a read-only inspection first:

```sh
sudo ~/dotfiles-linux/scripts/setup-ftpu --dry-run /dev/sda1
```

The dry run validates the device, UUID, existing account, paths and managed configuration sections. It does not install packages, acquire a setup lock, create files or accounts, mount anything, or reload SSH. Checks that require the mounted drive and staged SSH configuration run during actual setup.

To apply the setup from an interactive terminal:

```sh
sudo ~/dotfiles-linux/scripts/setup-ftpu /dev/sda1
```

For another home subnet, supply a network address with its prefix, for example `--allow-from 10.0.0.0/24`. IPv6 and Tailscale source addresses are denied for `ftpu`. The restriction uses the source address SSH sees; a connection forwarded or translated by another device may appear to originate from that device. This script does not change the Pi's firewall or router rules.

## What changes

- The drive mounts at `/my-fdd-drive`, identified persistently by its filesystem UUID.
- `/my-fdd-drive/PhoneBackups` is exposed inside the account's chroot as `/data` through a bind mount at `/home/ftpu/data`.
- The chroot is root-owned. The covered, unmounted `data` directory is root-owned with mode `0555`, so a failed mount cannot accept uploads onto the SD card.
- `ftpu` has no login shell or supplementary privileges. SSH forces SFTP and disables forwarding, tunnels, terminal allocation and user startup commands.
- NTFS-3G assigns the account's UID/GID across the volume, with directories accessible only to that user and files readable/writable only by that user. These Linux access rules affect the whole mounted drive, including existing files; other local users need administrator access. The phone sees only `PhoneBackups`.
- Both mounts disable executable files, device nodes and set-ID execution. The drive uses `nofail` and a 10-second device timeout. The bind mount explicitly depends on the drive mount.
- Marked sections in `/etc/fstab` and the end of `/etc/ssh/sshd_config` hold the generated configuration. Root-only identity state is stored under `/var/lib/setup-ftpu`.

Existing files are neither moved nor deleted. If `PhoneBackups` already exists as a real directory, its contents are retained and become accessible to the phone. A symlink at that path is rejected. An NTFS permissions mapping that overrides the requested UID/GID or masks causes verification to fail.

An existing account from the old script is rejected. Migrate that installation manually: inspect its files, mounts and SSH configuration before removing or changing anything. The script will not silently adopt a normal user or reinterpret old mount entries.

## Connect and verify

Use these settings in the phone app:

| Setting | Value |
| --- | --- |
| Protocol | SFTP |
| Host | Pi's home-network IP address |
| Port | 22 |
| Username | `ftpu` |
| Password | Set interactively during initial setup |
| Remote directory | `/data` |

Verify the server's SSH host-key fingerprint when connecting. On the Pi, obtain it with `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`.

Upload a small test file, then confirm it appears in `/my-fdd-drive/PhoneBackups`. Download it and compare the contents. Test rename and deletion on test files only. Check a second `barts` SSH login before closing the original administrative session.

Repeat runs update the same managed sections without duplicates and preserve an existing usable password. The account is locked while changes are applied. A failed run leaves it locked; inspect and fix the failure before retrying. Change its password later with `sudo passwd ftpu`.

## Missing drive and reconnecting

On boot without the drive, the Pi should still start and uploads should fail. A successful upload without the drive is a deployment failure that must be investigated before using this for backups.

After reconnecting, first confirm the expected UUID with `lsblk -f`, then start both mount units:

```sh
sudo systemctl reset-failed 'my\x2dfdd\x2ddrive.mount' home-ftpu-data.mount
sudo systemctl start 'my\x2dfdd\x2ddrive.mount' home-ftpu-data.mount
findmnt --mountpoint /my-fdd-drive
findmnt --mountpoint /home/ftpu/data
```

Use quotes around the escaped drive unit name. Alternatively, obtain it with `systemd-escape --path --suffix=mount /my-fdd-drive`. Do not run repair, forced mounting, or formatting commands merely because a mount fails; inspect the system journal and the drive first.

Before unplugging, stop phone transfers, then unmount `/home/ftpu/data` followed by `/my-fdd-drive`. Do not unplug a drive with writes in progress.

## Failure recovery

The script prints a root-only backup directory under `/var/backups/setup-ftpu.*`. It retains `fstab.before`, `sshd.before`, and staged files for inspection. On failure it attempts to restore changed configuration, reload systemd/SSH, and lock `ftpu`.

Packages, the account, directories and live mounts may remain after failure. They are not deleted automatically because doing so could destroy data or interrupt transfers. If account creation was interrupted before the identity file was written, inspect the account manually rather than deleting it blindly.

If automatic restoration fails, use the printed directory to restore the affected file from its `.before` backup. Validate SSH with `sudo /usr/sbin/sshd -t` before `sudo systemctl reload ssh`; run `sudo systemctl daemon-reload` after restoring `fstab`. Keep the existing SSH session open throughout. Do not restore old configuration over newer intentional changes without comparing it first.

## Tests

Run the unprivileged regression suite:

```sh
python3 ~/dotfiles-linux/tests/scripts/test_setup_ftpu.py
bash -n ~/dotfiles-linux/scripts/setup-ftpu
shellcheck ~/dotfiles-linux/scripts/setup-ftpu
```

For actual NTFS permissions and SSH/SFTP behavior, run the integration test in a disposable Debian container. This uses an NTFS image through FUSE, private container mounts, test accounts and an internal SSH listener. It does not expose a host port or use host loop devices. It requires Docker, `/dev/fuse`, and permission to create mounts inside the container; only the source tree is shared, read-only.

```sh
docker run --rm --device /dev/fuse --cap-add SYS_ADMIN \
  --security-opt apparmor=unconfined \
  --mount "type=bind,src=$HOME/dotfiles-linux,dst=/work,readonly" \
  -e FTPU_TEST_CONTAINER=1 debian:trixie-slim bash -c \
  'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server openssh-client sshpass ntfs-3g python3 && bash /work/tests/scripts/test_setup_ftpu_container.sh'
```

The container does not exercise a real Raspberry Pi reboot, USB removal, or systemd as PID 1. Before relying on the deployment, test reboot with the drive attached, boot without it, and reconnect/remount. Use test uploads and safe unmounts; do not pull the cable during a transfer.
