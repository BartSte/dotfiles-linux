# Calendar safety tests

Run the focused calendar suite:

```sh
bash dotfiles-linux/tests/calendar-sync/run_tests.sh
```

The backend uses the installed Khalorg pipx interpreter. Override it with the process-scoped `CALENDAR_TEST_PYTHON` variable if necessary. The interpreter needs Khalorg 0.2.1, icalendar, and orgparse.

All test files, calendar data, configuration, logs, and baselines stay in temporary directories. Set `TMPDIR` to the private scratch directory. No test connects to Outlook or modifies production data.

The full-path test uses real vdirsyncer filesystem storage for both sides. It starts a temporary loopback listener instead of DavMail. It does not use either real Outlook account. The shell wrapper tests separately cover gateway identity, locking, failures, and bounded signal cleanup.

The suite covers:

- A host without its private server marker cannot run the bridge.
- Normal timer runs only export projections. They never parse Org files as write requests.
- Edits require a UID and a matching baseline.
- Creation requires a separate explicit request and uses a stable request-derived UID.
- Retries retain the request and never repeat a successful creation.
- Stale edits and unsupported event types leave the calendar unchanged.
- Invitations and recurring events require Outlook in this first release.
- Verification detects a conflicting event change after local application.
- Server timestamp rewrites do not force another write.
- All-day dates survive a real export/edit round trip.
- Empty, missing, or damaged projection text cannot create calendar events.

Run the Neovim tests from the base dotfiles checkout:

```sh
nvim --headless -u NONE -l dotfiles/nvim/tests/calendar_bridge.lua
nvim --headless -u NONE -l dotfiles/nvim/tests/calendar_config.lua
```

The Neovim tests replace only SSH execution with controlled responses. They do not connect to another device.
