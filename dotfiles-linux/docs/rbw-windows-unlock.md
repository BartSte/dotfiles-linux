# Automatic rbw unlock on WSL

The Windows helper stores the vault master password with DPAPI protection for your Windows user.
Existing `rbw` commands use this password automatically when the vault needs an unlock.
Two-factor codes and API keys still use the previous password prompt.

The encrypted file is in `%LOCALAPPDATA%\rbw-windows-unlock`.
Its name identifies the vault account, server, and rbw profile through a SHA-256 hash.
The helper restricts the directory permissions to your Windows user.
It sends the password through process pipes. It never puts the password in command arguments or environment variables.
Windows PowerShell runs the local helper with a process-only execution policy override.
The helper does not change the Windows execution policy.

Programs with access to your Windows user account can retrieve the unlock secret.
Locking the Windows desktop does not prevent background retrieval.
`rbw lock` clears the in-memory keys, but the next command can unlock the vault again.

## Initial setup

Run these commands in an interactive WSL terminal:

```bash
rbw-windows-unlock enable
rbw-windows-unlock enroll
```

Enter the vault master password once in the normal password prompt.
The helper stores it with Windows protection. Later unlocks require no password prompt.
The first master-password prompt after enable can also enroll the password.
If the password is incorrect, the helper discards it when rbw requests another attempt.

Check the enrollment state:

```bash
rbw-windows-unlock status
```

After enrollment, retry the calendar service:

```bash
systemctl --user start calsync.service
systemctl --user status calsync.service --no-pager
```

## Recovery

If the vault password changes, run `rbw-windows-unlock enroll` again.
If Windows decryption fails, the helper uses the previous password prompt.
Background services cannot complete an interactive prompt.
Use the enrollment command in a terminal to restore automatic unlock.

To disable automatic unlock and remove the stored secret, run:

```bash
rbw-windows-unlock disable
rbw-windows-unlock forget
```

Both commands stop the rbw agent to clear its in-memory keys.
Disabling alone keeps the encrypted secret for later use.
Forgetting alone permits enrollment at the next master-password prompt.

## Checks

Run `bash tests/bitwarden/test_windows_unlock.sh` from the dotfiles-linux directory.
The checks require Windows PowerShell and WSL interop.
They use a temporary synthetic account and remove its encrypted secret after the run.
They do not read or change your vault.
