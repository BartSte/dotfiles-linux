# Local Outlook calendars

Run `mycalsync --verbose` to synchronize the two Outlook calendars locally.
The order is DavMail startup, vdirsyncer sync, and `khalorg list` export.
The process uses a local lock and stops its own child processes after failure or interruption.

The output directory is `${XDG_DATA_HOME:-$HOME/.local/share}/khalorg/agendas`.
Exports cover today through 365 days. Each successful export replaces its file atomically.
Failed exports keep the previous file. Unchanged exports retain their modification times.
An empty export can be valid; it never requests deletion of calendar events.

`khalorg-local` connects the Neovim plugin to the same lock.
It permits explicit creation, edits, and listing. It rejects deletion and whole-file sync.
A lock wait that exceeds 30 seconds fails without a calendar operation.
Retry the action after the active timer cycle finishes.

Use local inbox files for captures and unfinished edits.
Keep the UID when editing an existing event. Save the UID that the plugin adds after creation.
After an explicit action, the Neovim configuration runs `mycalsync` to upload and refresh.
If upload fails, retry synchronization rather than creating the event again.

The Arch and Pi layers install five-minute user timers.
They use independent storage and authentication. Preserve live DavMail properties during upgrades.
The Pi WebDAV unit serves the standard data directory, so keep its XDG data root at the default.

The [base calendar instructions](https://github.com/BartSte/dotfiles/blob/master/README.md#calendar-setup)
include Neovim actions, offline limits, and recovery instructions.
The [Pi WebDAV guide](https://github.com/BartSte/dotfiles-pi/blob/main/dotfiles-pi/calendar-webdav/README.md)
describes phone viewing.
