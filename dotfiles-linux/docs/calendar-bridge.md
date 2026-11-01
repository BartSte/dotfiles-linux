# Safe calendar edits through the Pi

## Ownership

The Pi is the only Outlook bridge. Dropbox continues to deliver calendar projections to the laptop. It does not carry write requests.

`calsync` exports these files:

- `~/dropbox/generated/outlook_personal.org`
- `~/dropbox/generated/outlook_work.org`

A normal timer cycle never imports Org changes. Removing an entry, subtree, or file cannot request an Outlook deletion. A later export restores the calendar view.

Only `calendar-submit` accepts writes. It receives one JSON request over SSH and runs `calsync` with a private request file. The Pi holds its calendar lock across the inbound sync, baseline comparison, local application, outbound sync, another remote sync, verification, and export.

The bridge requires a private marker at `~/.config/calendar-bridge/server`. Its content must equal the current hostname. Install this marker on the Pi only. Do not copy it to the laptop or share it through Dropbox.

The calendar service and existing file-transfer service remain unchanged. Do not run the full dotfiles installer during this release. The remote repository contains an unrelated DavMail Graph authentication change.

## Laptop workflow

Shared calendar files open read-only in Neovim.

To edit an event:

1. Open the event in the agenda or calendar file.
2. Run `:CalendarDraft`, or select the calendar edit export action.
3. Edit the local draft.
4. Save the draft.
5. Run `:CalendarApply`.
6. Save the draft after confirmation updates its baseline.

Drafts live under Neovim's local state directory, in `calendar-bridge/drafts/`. Dropbox cannot replace these files.

The personal and work capture templates also use local draft files. Run `:CalendarNew` on a complete captured event to create it. Saving a draft alone never creates an Outlook event.

Delete events in Outlook only. There is no Neovim deletion action in this workflow.

The first release supports title, description, location, and date changes for plain non-recurring events. It preserves the UID and unrelated iCalendar data. Use Outlook for invitations, recurring events, unsupported property changes, and ambiguous DST times. The server rejects these requests without changing the event.

Bart's Neovim configuration uses the literal SSH alias `pi`. This preserves the laptop's existing SSH settings. Set `CALENDAR_BRIDGE_HOST` before starting Neovim if another destination is required. The laptop needs non-interactive SSH access. Requests travel through stdin, not shell interpolation.

## Pending requests and conflicts

Every request has a UUID and a durable local JSON copy before SSH starts. The draft also records the request UUID. Do not remove that identifier to repeat an uncertain creation.

If the connection fails, keep the draft. Use the exact retry command shown by Neovim:

```vim
:CalendarRetry <request-uuid>
```

A retry uses the original saved payload. It does not replace that request with newer buffer text. The server checks the request ID and content before reuse.

The exported `BRIDGE_BASELINE` identifies the calendar event version. If that event changes, the server rejects the stale edit. The pending draft remains available. Start a fresh draft from the latest projection and resolve the difference manually.

A successful response means that calsync completed its push, another sync, verification of the intended event fields, and export. A local file save or local receipt alone is not a successful Outlook update.

If the source buffer changes during a request, Neovim saves the response but does not write a UID or baseline into that changed buffer. Inspect the saved result before another creation attempt.

Pending requests and result files remain under Neovim's state directory in `calendar-bridge/pending/`. Server request receipts remain under `${XDG_STATE_HOME:-~/.local/state}/calendar-bridge/requests/`. These files contain private event text and use owner-only file permissions.

If the server fails between its durable prepared receipt and the calendar write, automatic replay fails closed. Inspect the request and current event before creating a new attempt. Do not delete a receipt and blindly retry a creation.

## Projection recovery

The exporter preserves replaced local projection text when it differs from the last published version. These recovery copies live under the Pi's local state directory in `calendar-bridge/projections/`.

This archive is defense in depth. It is not a distributed lock. The supported laptop workflow edits separate local drafts, not shared projection files. Other editors or manual overrides are outside this workflow.

Before the first live export, preserve all current Org files and Khalorg baselines. They can contain pending edits from the old workflow. Do not discard them as generated files without review.

## Verification limits

The automated full-path tests use real vdirsyncer and synthetic filesystem calendars. They do not prove DavMail or Outlook account behavior. A live read/export cycle and laptop SSH test are separate rollout checks. Do not send test invitations or create real Outlook events without authorization.
