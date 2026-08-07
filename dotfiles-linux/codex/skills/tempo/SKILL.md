---
name: tempo
description: Create, repair, audit, and verify Tempo Timesheets worklogs through the Jira and Tempo REST APIs. Use when Codex must fill a Tempo timesheet, convert Jira or GitHub activity suggestions into four fixed work blocks, assign required Tempo Accounts, map Jira worklog IDs to Tempo IDs, verify submitted time, or remember Jira-prefix-to-account mappings. Never use browser or desktop automation.
---

# Tempo

Use the API-only client in `scripts/tempo.py`. Do not click through Jira or Tempo. Do not use browser or desktop automation.

## Workflow

1. Read `references/configuration.md` and `references/accounts.json`.
2. Collect the suggestions for the requested day. Keep only items that have a Jira issue key.
3. Convert the suggestions to the manifest format in `references/configuration.md`.
4. Run `python scripts/tempo.py plan <manifest>`.
5. If the plan reports an unknown Jira prefix, stop.
6. If the Jira prefix is unknown, search the Tempo accounts with `python scripts/tempo.py accounts --query <text>`.
7. Use the Jira project context to identify an unambiguous account.
8. If the account remains uncertain, ask the user which account corresponds to the Jira prefix.
9. Include the Jira prefix and candidate account names in the question.
10. After you resolve the account, add its prefix, key, and exact name to `references/accounts.json`.
11. Use `apply_patch` for this edit.
12. Run `python scripts/tempo.py verify <manifest>` before an apply. This detects entries that already exist.
13. If the user asked to fill or repair the timesheet, run `python scripts/tempo.py apply <manifest>`.
14. Report the verified issue keys, times, durations, and accounts. Report skipped suggestions separately.

An explicit request to fill, log, repair, or update a timesheet authorizes the matching API writes. A request to inspect, plan, or verify does not authorize writes.

## Required behavior

- Use `rbw get atlassian_tempo_token` for the Tempo token.
- Use the vault item names in `references/configuration.md` for Jira credentials.
- Never print, store, or place credentials in command arguments.
- Resolve known Jira prefixes through `references/accounts.json`.
- If a Jira prefix is unknown, inspect the Tempo accounts and the Jira project context.
- If this evidence does not identify one account, ask the user which Account corresponds to the Jira prefix.
- Do not guess an account. Do not create worklogs until all Jira prefixes have account mappings.
- Save each resolved mapping in `references/accounts.json` for later timesheets.
- Treat the account key as the stable identifier. Keep the account name for user-readable output.
- Skip activity that has no Jira issue key.
- Use these work blocks: `08:30–10:30`, `10:30–12:30`, `13:30–15:30`, and `15:30–17:30`.
- If a work block has no suggestions, leave it empty.
- If a work block has suggestions, fill all 120 minutes.
- Preserve the order of the suggestions during time-range expansion.
- Do not create overlapping worklogs.
- Treat manifest times and durations as source suggestions. Treat the plan output as the final schedule.
- Keep the issue key and description from the user.
- Use `Europe/Berlin` unless the user gives another time zone.
- Prevent duplicate worklogs. The client matches the author, issue, date, start time, duration, and description.
- If a matching Jira worklog exists without an Account value, assign the value instead of creating another worklog.
- Stop on an existing, incorrect Account value. Do not overwrite it automatically.
- Verify every write through the Tempo API before reporting success.
- If Jira creation succeeds but Tempo synchronization fails, report the Jira worklog ID. A later apply can finish the Account assignment without duplicating the Jira worklog.

## Commands

Run commands from this skill directory.

```bash
python scripts/tempo.py plan /path/to/day.json
python scripts/tempo.py accounts --query inspector
python scripts/tempo.py verify /path/to/day.json
python scripts/tempo.py apply /path/to/day.json
```

Use `plan` for local validation. Use `accounts` and `verify` for read-only API calls. Only `apply` creates worklogs or missing Account values.

## API model

The client first creates the worklog in Jira. It then maps the Jira worklog ID to the Tempo worklog ID and assigns the required `_Account_` work attribute. See `references/configuration.md` for the endpoints and recovery rules.
