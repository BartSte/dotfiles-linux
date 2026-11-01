# Calendar checks

Run `bash dotfiles-linux/tests/calendar-sync/run_tests.sh` from the repository checkout.
The checks use temporary files and synthetic calendars. They do not contact Outlook.
The real export check requires Khalorg and its Khal dependency.

The suite covers process cleanup, listener ownership, interruption, failed exports,
atomic replacement, unchanged exports, missing or damaged Org text, and local locking.
It also checks real timed and all-day exports, explicit creation and edits, and UID preservation.
The Neovim configuration check is in the base repository:

```sh
nvim --headless -u NONE -l dotfiles/nvim/tests/calendar_config.lua
```

Live verification uses normal calendar synchronization and exports only.
Phone auto-sync acceptance requires a check in Orgzly Revived on Android.
