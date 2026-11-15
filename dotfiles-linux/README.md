# Linux dotfiles

This layer contains shell, Git, mail, calendar, Codex, and command-line configuration.
Use it with the base layer and the appropriate Arch or Raspberry Pi layer.
See the [base overview](https://github.com/BartSte/dotfiles/blob/master/README.md) for installation.

See the [open command guide](docs/open.md) for file, URL, WSL, and tmux behavior.

## Tailscale

The main setup installs Tailscale if missing and enables its systemd service at boot.
It uses the official Linux installer and requires Linux `sudo` access.
To run this module separately, use `~/dotfiles-linux/tailscale/main`.

On each new machine, run `~/dotfiles-linux/tailscale/auth` and open the login URL.
The repository's `auth` script also runs this step.
Each machine keeps its own identity in `/var/lib/tailscale`; do not copy this directory into dotfiles.
Repeated setup runs preserve the existing login.

On WSL 2, enable systemd first with `~/dotfiles-linux/wsl/main`.
Then run `wsl --shutdown` from Windows, reopen WSL, and run the Linux setup.
This requires no Windows administrator access if WSL 2 is already installed.
Tailscale connects the WSL environment; Windows applications do not automatically use it.
Avoid simultaneous Tailscale connections on Windows and inside WSL.

## Calendars

Each machine connects to Outlook through its own DavMail, vdirsyncer, and khal storage.
`mycalsync` exports local Org agendas through Khalorg without importing Org changes.
The Neovim configuration uses the existing `nvim-khalorg` plugin for explicit event actions.
See the [calendar guide](docs/calendars.md) for the local workflow.
On WSL, [Windows-protected rbw unlock](docs/rbw-windows-unlock.md) permits automatic vault access after one enrollment.
The Pi adds read-only WebDAV for Orgzly Revived; the laptop does not use that service.

This repository owns `dotfiles-linux/README.md`. The base repository owns `~/README.md`.
