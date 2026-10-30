# KMonad

The complete Linux configuration lives in `~/dotfiles-secret/kmonad/linux.kbd`.
It includes personal macros. Keep the configuration and its parser diagnostics
out of public repositories and terminal logs.

Run `~/dotfiles-linux/kmonad/main` to validate and install the private configuration,
install the service, and restart KMonad. This command requires sudo access.

The service reads `/etc/kmonad/config.kbd`. The installer gives this file mode
`600` and root ownership. The old `/etc/systemd/system/home_row_modifiers.kbd`
file is no longer used after installation.

The installer skips WSL by default. To install the files without enabling or
restarting the service, run:

```bash
~/dotfiles-linux/kmonad/main --install-only
```

Set `DOTFILES_SECRET_DIR` to use another private dotfiles directory.

The private repository also contains `kmonad/windows.kbd`. Keep the layers in
both files consistent when you change key assignments. Each file retains its
platform-specific input and output settings.
