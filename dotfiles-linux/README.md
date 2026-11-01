# Linux dotfiles

This layer contains shell, Git, mail, calendar, Codex, and command-line configuration.
Use it with the base layer and the appropriate Arch or Raspberry Pi layer.
See the [base overview](https://github.com/BartSte/dotfiles/blob/master/README.md) for installation.

## Calendars

Each machine connects to Outlook through its own DavMail, vdirsyncer, and khal storage.
`mycalsync` exports local Org agendas through Khalorg without importing Org changes.
The Neovim configuration uses the existing `nvim-khalorg` plugin for explicit event actions.
See the [calendar guide](docs/calendars.md) for the local workflow.
The Pi adds read-only WebDAV for Orgzly Revived; the laptop does not use that service.

This repository owns `dotfiles-linux/README.md`. The base repository owns `~/README.md`.
