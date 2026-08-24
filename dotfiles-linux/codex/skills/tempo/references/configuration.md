# Tempo configuration

## Connection

- Jira site: `https://fleetcleaner.atlassian.net`
- Jira email: `rbw get --field username atlassian_token`
- Jira API token: `rbw get atlassian_token`
- Tempo API token: `rbw get atlassian_tempo_token`
- Default time zone: `Europe/Berlin`
- Required Tempo work attribute: `_Account_`

The client also accepts `JIRA_EMAIL`, `JIRA_API_TOKEN`, and `TEMPO_API_TOKEN`. Environment variables take precedence over `rbw`. Do not save secret values in this skill.

## Manifest

Create one JSON manifest for one day. Use 24-hour local times. Durations are positive whole minutes.

The manifest contains source suggestions. The client expands them into the final worklog ranges.

```json
{
  "date": "2026-06-30",
  "timezone": "Europe/Berlin",
  "entries": [
    {
      "issue": "FL-217",
      "start": "08:45",
      "duration_minutes": 30,
      "description": "Inspection Data Mapper: mapper failure does not stop processing"
    },
    {
      "issue": "PI-135",
      "start": "10:45",
      "duration_minutes": 45,
      "description": "Improve grid coordinates"
    }
  ]
}
```

Do not add suggestions without a Jira issue key. List them as skipped items in the final report.

## Work blocks

The client divides the day into these fixed blocks:

- `08:30–10:30`
- `10:30–12:30`
- `13:30–15:30`
- `15:30–17:30`

An empty block stays empty. An occupied block gets exactly 120 minutes of worklogs.

Source suggestions must not overlap. A suggestion can cross a block boundary.

For a crossing suggestion, the client adds its intersecting part to each block. Time in the lunch gap does not fill a block.

The client sorts the suggestions in each block by their original start time. It then applies these rules:

1. Start the first worklog at the start of the block.
2. End each worklog at the original start of the next suggestion.
3. End the last worklog at the end of the block.

For example, a block contains `09:00–09:15` and `10:00–10:30`. The final ranges are `08:30–10:00` and `10:00–10:30`.

The client rejects a suggestion that occurs only outside the fixed blocks.

## Account mappings

`accounts.json` maps each Jira project prefix to one Tempo account.

If a prefix is absent, list the Tempo accounts. Use the Jira project context to find an unambiguous match.

If the match remains uncertain, ask the user which Account corresponds to the Jira prefix. Include plausible account names and keys.

Do not create worklogs before you resolve every prefix. After you resolve a mapping, add it to `accounts.json`.

The mapping key is the uppercase Jira prefix. The account `key` must match the Tempo account key. The account `name` is the exact display name returned by Tempo.

Known examples include `FL → Fleet Inspector Light`, `FIR → Fleet Inspector WBSO`, and `PI → Process improvements Software`.

## API sequence

The client uses these endpoints:

1. `GET /rest/api/3/myself` gets the current Jira account ID.
2. `GET /rest/api/3/issue/{issueKey}/worklog` checks for a duplicate.
3. `POST /rest/api/3/issue/{issueKey}/worklog` creates a missing Jira worklog.
4. `GET https://api.tempo.io/4/accounts` validates account mappings.
5. `POST https://api.tempo.io/4/worklogs/jira-to-tempo` maps Jira IDs to Tempo IDs.
6. `POST https://api.tempo.io/4/worklogs/work-attribute-values/search` reads Account values.
7. `POST https://api.tempo.io/4/worklogs/work-attribute-values` creates missing Account values.
8. The search endpoint verifies the final values.

Jira worklog comments use Atlassian Document Format. Jira worklog start values include the UTC offset from the manifest time zone.

## Recovery rules

- A repeated apply does not create a matching worklog again.
- A repeated apply can assign an Account value after delayed Jira-to-Tempo synchronization.
- The plan output contains the expanded worklog ranges.
- The create-value endpoint cannot replace an existing attribute value. If the current Account is incorrect, stop.
- Never delete a worklog during automatic recovery.
- Never use the browser as a fallback.
