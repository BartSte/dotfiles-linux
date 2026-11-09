# Restricted phone backups over SFTP

`setup-ftpu` configures the `ftpu` account for an NTFS drive. `/data` exposes `PhoneBackups` for automatic phone uploads; `/drive` exposes the entire external drive with read-write access for manual file management. It uses password authentication and accepts your home LAN (`192.168.1.0/24` by default) plus one Android phone over Tailscale. A dedicated SFTP service uses port **2222** on both networks. Other SSH accounts, including `barts`, keep their existing settings.

The script supports Debian-based Raspberry Pi systems with an existing OpenSSH configuration and a `barts` administrative account. Keep `setup-ftpu-support.py` alongside the script. Python 3 and the standard Debian account, mount, and systemd tools must already be available. It installs missing `openssh-server` and `ntfs-3g` packages without upgrading the rest of the system. Tailscale must already be installed and signed in on the Pi and phone; use `--lan-only` to skip Tailscale.

## Before setup

Keep another copy of important files. The phone can overwrite and delete files anywhere on the external drive, including backups; this setup does not provide version history or protection from drive failure.

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

For another home subnet, supply a network address with its prefix, for example `--allow-from 10.0.0.0/24`. The restriction uses the source address SSH sees; a connection forwarded or translated by another device may appear to originate from that device. Router rules are not changed.

## Automatic Tailscale setup

On first setup the script selects the only Android device, or the only online Android device if there are several. It shows the selected phone before setup and records its stable Tailscale device ID after success. Later runs keep that same phone even if another phone is online. Missing, expired or ambiguous devices cause an error rather than granting access to a replacement automatically.

If selection is ambiguous, use `--tailscale-phone 'Bart Phone'` (or its MagicDNS name, Tailscale IP or device ID). Use the same option to replace the saved device intentionally. Only the selected phone's exact IPv4 and IPv6 Tailscale addresses are allowed; the whole tailnet is not added. `--lan-only` removes Tailscale access from the generated service configuration while keeping the saved phone choice for future use.

The script creates and enables `ftpu-sftp.service`, generates its configuration, and prints the Pi's MagicDNS name, connection settings and SSH host-key fingerprint. It keeps Tailscale SSH and ordinary administrative SSH unchanged. The separate port is necessary because Tailscale SSH handles port 22 on the Pi's Tailscale addresses independently of OpenSSH.

If UFW is active, the script adds rules for port 2222 from the LAN and selected phone. Repeat runs remove obsolete rules marked `setup-ftpu` and preserve other rules. Failed setup attempts restore the saved UFW rule files. Other firewall managers are not configured automatically.

Tailnet access policy must allow the phone to reach the Pi on **TCP 2222**. The local CLI cannot edit that policy, and the Pi cannot prove that an inbound phone connection is permitted. If connection fails despite the service running, check that policy. No policy change is needed when it already permits the connection.

Tailscale SSH on port 22 has its own authorization policy and does not apply this service's OpenSSH chroot or source restrictions. Do not grant the backup account access through Tailscale SSH; trusted administrative identities retain the access your tailnet policy already grants them.

## What changes

- The drive mounts at `/my-fdd-drive`, identified persistently by its filesystem UUID.
- `/my-fdd-drive/PhoneBackups` is exposed inside the account's chroot as `/data` through a bind mount at `/home/ftpu/data`.
- `/my-fdd-drive` is also exposed as `/drive` through a bind mount at `/home/ftpu/drive`. Existing directories and files are readable and writable there.
- The chroot is root-owned. Both covered, unmounted directories are root-owned with mode `0555`, so a failed mount cannot accept uploads onto the SD card.
- `ftpu` has no login shell or supplementary privileges. SSH forces SFTP and disables forwarding, tunnels, terminal allocation and user startup commands.
- NTFS-3G assigns the account's UID/GID across the volume, with directories accessible only to that user and files readable/writable only by that user. These Linux access rules affect the whole mounted drive, including existing files; other local users need administrator access.
- All three mounts disable executable files, device nodes and set-ID execution. The drive uses `nofail` and a 10-second device timeout. Both bind mounts explicitly depend on the drive mount.
- systemd owns the NTFS driver process, so closing the setup terminal or finishing a background setup job does not stop the drive mount.
- Marked sections in `/etc/fstab` and the end of `/etc/ssh/sshd_config` hold the generated configuration. Root-only identity state is stored under `/var/lib/setup-ftpu`.
- `/etc/ssh/sshd_config.ftpu` and `/etc/systemd/system/ftpu-sftp.service` configure the dedicated server on port 2222. The existing port-22 OpenSSH server retains LAN-only `ftpu` restrictions for compatibility. Phone selection is recorded in `/var/lib/setup-ftpu/phone.json`.

Existing files are neither moved nor deleted. If `PhoneBackups` already exists as a real directory, its contents are retained and become accessible to the phone. A symlink at that path is rejected. An NTFS permissions mapping that overrides the requested UID/GID or masks causes verification to fail.

An existing account from the old script is rejected. Migrate that installation manually: inspect its files, mounts and SSH configuration before removing or changing anything. The script will not silently adopt a normal user or reinterpret old mount entries.

## Connect and verify

Use these settings in the phone app:

| Setting | Value |
| --- | --- |
| Protocol | SFTP |
| Host | Pi's MagicDNS name printed by setup, or its Tailscale IP |
| Port | 2222 |
| Username | `ftpu` |
| Password | Set interactively during initial setup |
| Remote directory | `/data` |

Keep existing automatic backup pairs pointed at `/data/Camera`. For manual file
management, open the saved account in FolderSync's File Manager, go up to `/`,
and open `/drive`. Its directories and files support download, upload, rename,
and deletion. `/drive/PhoneBackups` and `/data` are two views of the same files;
changes through either path affect the same stored data. The Pi's own filesystem
remains outside the chroot.

Keep Tailscale connected on the phone for this host to work both at home and away. For a direct LAN connection without Tailscale, use the Pi's LAN IP with the same port and credentials. To back up away from home, FolderSync's connection settings must also allow the network you are using (for example mobile data); do not restrict that folder pair to your home Wi-Fi.

Verify the server's SSH host-key fingerprint when connecting. On the Pi, obtain it with `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`.

Upload a small test file, then confirm it appears in `/my-fdd-drive/PhoneBackups`. Download it and compare the contents. Test rename and deletion on test files only. Check a second `barts` SSH login before closing the original administrative session.

Repeat runs update the same managed sections without duplicates and preserve an existing usable password. An interactive terminal is needed only when setting an initial or locked account's password. The account is locked while changes are applied. A failed run leaves it locked; inspect and fix the failure before retrying. Change its password later with `sudo passwd ftpu`.

## Missing drive and reconnecting

On boot without the drive, the Pi should still start and uploads should fail. A successful upload without the drive is a deployment failure that must be investigated before using this for backups.

After reconnecting, first confirm the expected UUID with `lsblk -f`, then start both mount units:

```sh
sudo systemctl reset-failed 'my\x2dfdd\x2ddrive.mount' home-ftpu-data.mount home-ftpu-drive.mount
sudo systemctl start 'my\x2dfdd\x2ddrive.mount' home-ftpu-data.mount home-ftpu-drive.mount
findmnt --mountpoint /my-fdd-drive
findmnt --mountpoint /home/ftpu/data
findmnt --mountpoint /home/ftpu/drive
```

Use quotes around the escaped drive unit name. Alternatively, obtain it with `systemd-escape --path --suffix=mount /my-fdd-drive`. Do not run repair, forced mounting, or formatting commands merely because a mount fails; inspect the system journal and the drive first.

Before unplugging, stop phone transfers, unmount both `/home/ftpu/data` and `/home/ftpu/drive`, then unmount `/my-fdd-drive`. Do not unplug a drive with writes in progress.

## Failure recovery

The script prints a root-only backup directory under `/var/backups/setup-ftpu.*`. It retains `fstab.before`, `sshd.before`, previous dedicated SFTP files, UFW rule backups when applicable, and staged files for inspection. On failure it attempts to restore changed configuration, restore the dedicated service's previous state, reload systemd/SSH and UFW as needed, and lock `ftpu`.

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
docker run --rm --device /dev/fuse --cap-add SYS_ADMIN --cap-add NET_ADMIN \
  --security-opt apparmor=unconfined \
  --mount "type=bind,src=$HOME/dotfiles-linux,dst=/work,readonly" \
  -e FTPU_TEST_CONTAINER=1 debian:trixie-slim bash -c \
  'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server openssh-client sshpass ntfs-3g python3 iproute2 && bash /work/tests/scripts/test_setup_ftpu_container.sh'
```

The container uses simulated phone IPv4/IPv6 addresses on loopback to test source restrictions. It does not exercise actual Tailscale transport, tailnet policy, a Raspberry Pi reboot, USB removal, or systemd as PID 1. Before relying on the deployment, test a connection from the phone with Wi-Fi disabled, reboot with the drive attached, boot without it, and reconnect/remount. Use test uploads and safe unmounts; do not pull the cable during a transfer.
