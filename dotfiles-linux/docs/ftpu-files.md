# Files synchronization over Tailscale

FreeFileSync connects local `~/Files` to `ftpu` SFTP `/drive/Files` on port 2222.
Android FolderSync uses the same server folder. No remote mount is required.

The client uses database-based rules for new and edited files in both directions.
Both deletion actions are `none`. Unresolved conflicts stay unchanged for manual review.
Skipped conflicts and transfer failures appear in the logs and return a nonzero exit status.
Renames can leave the old name on the other device while deletions are disabled.

The base layer provides initialization. Linux owns the client and units.
Arch owns package installation and the Tailscale daemon.
The FreeFileSync GUI and batch commands require a desktop session.
The normal installers do not configure a personal endpoint or enable the sync timer.

## Server preparation

1. Confirm the existing drive partition and mount UUID on the Pi.
2. Run `setup-ftpu --dry-run --tailscale-laptop LAPTOP_NAME PARTITION` as root on the Pi.
3. Review the selected phone, laptop, and proposed exact source rules.
4. Run the same command without `--dry-run` against the verified partition.
5. Confirm phone SFTP access still works.
6. Confirm tailnet policy permits the laptop to reach the Pi on TCP 2222.
7. Exclude `*.ffs_db`, `*.ffs_lock`, and `*.ffs_tmp` in the Android Files pair, including subfolders.

Use `~/dotfiles-linux/scripts/setup-ftpu`. Do not guess the drive partition.
The saved laptop identity survives later setup runs. No whole-tailnet allowance is added.
Existing phone backup pairs and history jobs remain separate.
The Files exclusions prevent the phone from restoring an old FreeFileSync database onto the server.
Apply these exclusions to the Files pair only. Keep deletion syncing off.

## Laptop enrollment

1. Run the Linux and Arch installers.
2. Sign in to Tailscale with `sudo tailscale up` if needed.
3. Configure and unlock the existing `rbw` vault.
4. Store the ftpu password in the password field of a dedicated login item.
5. Run `~/dotfiles-linux/files/auth` from the desktop terminal.
6. Enter the Pi MagicDNS name and the vault item's unique name or ID.
7. Inspect any existing `~/Files` before creating or using that folder.
8. Run `mkdir -p ~/Files` if the path is the intended working folder.
9. Run `ftpu-files preview` and enter the SFTP password when prompted.
10. Review both paths and the proposed actions before synchronization.

`preview` opens the comparison GUI. It does not automatically start synchronization.
The GUI permits manual actions, so leave deletion rules unchanged.
On first comparison, different files with the same name need manual review.
Preserve existing laptop documents and Dropbox originals until comparison is complete.

The private profile is `~/.config/ftpu-files/config.json`, mode 600.
It contains the endpoint and vault item name, but no password.
Use `--host`, `--password-entry`, and `--local` with `ftpu-files configure` for scripted enrollment.
Existing profiles are never overwritten by enrollment or installation.

## First sync and schedule

1. Test a disposable file in the shared `Test` folder in each direction.
2. Run `ftpu-files sync` from the desktop session.
3. Verify the transferred file contents on the Pi and laptop.
4. Verify an Android edit arrives on the laptop through the Pi.
5. Test simultaneous edits with disposable files and inspect the conflict report.
6. Run `ftpu-files enable` after a successful batch run and the file checks.

The timer starts after two minutes and repeats five minutes after each completed run.
The client refuses overlapping runs and stops before launch if Tailscale is offline.
FreeFileSync reports unreachable servers as transfer errors. No local directory is used as a remote fallback.
Offline local files remain usable. A later timer run retries after reconnection.
The client never unlocks the vault automatically. A locked vault prevents that run.

Use these commands:

```sh
ftpu-files preview
ftpu-files sync
ftpu-files status
ftpu-files disable
journalctl --user -u ftpu-files.service
```

The timer runs only in a desktop session, without user lingering.
The Arch Sway configuration runs `ftpu-files session-start` at login.
This command imports the display environment and starts `graphical-session.target`.
It does not enable the timer. Other desktops can run this command through their session startup facility.
Both Arch Sway profiles enable XWayland for the GTK2 FreeFileSync binary.
The enable command also initializes the current graphical session.
The standard service expects the default `~/.config` location. Adapt it before using a custom XDG config root.

## Credentials and recovery

Batch jobs obtain the password from `rbw` at runtime.
They put it in a mode-600 temporary FreeFileSync profile and remove it after a normal process exit.
The profile uses the desktop runtime directory, or the system temporary directory if no runtime directory exists.
An interrupted process can leave a private temporary profile until session or temporary-file cleanup.
The password is never an argument or part of a public template.
FreeFileSync can retain private connection history in its own user configuration.
Keep that configuration, `~/.config/ftpu-files`, and the client state outside all Git repositories.
Tailscale provides the authenticated network path. Do not assume FreeFileSync reads OpenSSH `known_hosts`.

The client preserves overwritten versions in `~/.local/state/ftpu-files/versions`.
Logs are in `~/.local/state/ftpu-files/logs`. Keep these folders private and monitor disk usage.
Pi history also protects files changed by Android, subject to its snapshot interval.
Neither same-drive history nor local versioning replaces an independent backup.
The retired `Generated` folder stays excluded.

## Deletion syncing later

Deletion propagation is deliberately unavailable in this initial client command.
Do not change the temporary profiles or replace this job with Mirror mode.
First establish an independent backup and verify a restore.
Reconcile the phone, Pi, and laptop copies before changing the rules.
Then change both database-based Delete directions to their opposite destinations.
Coordinate that change with Android FolderSync and test deletion in both directions.
Keep versioning enabled. Preserved phone copies can otherwise restore deleted files.

## Rollback

Run `ftpu-files disable` to stop scheduling.
Wait for any active transfer before stopping `ftpu-files.service`.
Preserve `~/Files`, the Pi files, version history, and Dropbox originals.
Remove the client unit links only after disabling the timer.
Use the existing server setup backup procedure to reverse server access changes.
No Syncthing pairing, remote mount, Dropbox cancellation, or cloud deletion is part of this setup.

## References

- [FreeFileSync synchronization settings](https://freefilesync.org/manual.php?topic=synchronization-settings)
- [SFTP setup](https://freefilesync.org/manual.php?topic=ftp-setup)
- [Batch jobs](https://freefilesync.org/manual.php?topic=schedule-batch-jobs)
- [File versioning](https://freefilesync.org/manual.php?topic=versioning)
