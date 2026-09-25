---
name: jira-automation
description: Inspect and update exact non-secret values in Jira Cloud Automation rules through the official Automation REST API. Use for incoming-webhook conditions, callback contract migrations, rule discovery, and post-write validation. Do not use for credentials, Jira work item updates, or workflow transitions.
---

# Jira Automation

Use `scripts/jira-automation.cjs` for Automation rule reads and exact value updates.
The script keeps the API token in memory and validates the complete saved rule after each update.

## Authorization

- A request to inspect or audit rules authorizes `list` and `plan` only.
- An explicit request to update a rule authorizes the matching `apply` command.
- Do not infer permission for a different rule or a different value.
- Do not put credentials, tokens, or webhook secrets in a replacement manifest.
- Read the current rule before each update.
- Stop if the rule name, state, old value, or match count differs from the manifest.
- Do not retry an unchanged failed write.
- If post-write validation fails, report an uncertain saved state and stop.

For a callback contract migration, make sure that the producer contract is active first.
If the producer is not active, stop and report the deployment dependency.
Do not leave the live callback rule incompatible with the active producer.

## Jira identity and site

Use `twg` first because Jira is the source of truth.

```bash
twg api jira:/rest/api/3/myself
```

Get the account email from `emailAddress`.
Get the cloud ID from the UUID in `self`.

The Automation rule API does not accept the stored TWG OAuth credential.
The `twg api` command also blocks a custom `Authorization` header.
Use the helper only after the user authorizes API-token access.

Set the non-secret account values in the process environment:

```bash
export ATLASSIAN_EMAIL="user@example.com"
export ATLASSIAN_CLOUD_ID="00000000-0000-0000-0000-000000000000"
```

The helper reads the API token from `rbw get atlassian_token` by default.
Set `ATLASSIAN_TOKEN_RBW_ITEM` if the user authorizes a different vault item.
Never print the token or place it in a command argument.

## Rule discovery

Run commands from this skill directory.

```bash
node scripts/jira-automation.cjs list
node scripts/jira-automation.cjs list --name "Exact rule name"
node scripts/jira-automation.cjs inspect <rule-uuid> --contains <request marker>
```

Require one exact rule match before an update.
Record its UUID, name, and state.
`inspect` reports matching string paths and hashes. It does not print rule content or secrets.

## Exact value updates

Create a temporary JSON manifest with this structure:

```json
{
  "rule_uuid": "00000000-0000-0000-0000-000000000000",
  "expected_name": "Exact rule name",
  "expected_state": "ENABLED",
  "replacements": [
    {
      "first": "{{webhookData.contract_version}}",
      "operator": "EQUALS",
      "old_second": "3",
      "new_second": "4"
    }
  ]
}
```

Each replacement must match exactly one condition in `rule.components`.
Use the exact current operator and values.

Run a read-only plan before the update:

```bash
node scripts/jira-automation.cjs plan /absolute/path/update.json
```

If the plan matches the authorized change, apply it:

```bash
node scripts/jira-automation.cjs apply /absolute/path/update.json
```

The `apply` command performs these operations:

1. Read the current rule again.
2. Require the expected UUID, name, state, and old values.
3. Remove only API read-only fields from the update payload.
4. Update the exact condition values.
5. Send one `PUT` request.
6. Read the saved rule.
7. Compare all writable fields with the submitted payload.

Remove the temporary manifest after the result is valid.
Report the rule UUID, name, state, and changed values.

## Exact request-body update

Use this route only after the producer accepts the new request fields.
Read the rule with `inspect` and identify one `jira.issue.outgoing.webhook` component.
Require that its current `customBody` hash matches the approved old body.
Do not change another component, including an unused variable with similar text.

Create a temporary JSON manifest:

```json
{
  "rule_uuid": "00000000-0000-0000-0000-000000000000",
  "expected_name": "Exact rule name",
  "expected_state": "ENABLED",
  "component_id": "00000000-0000-0000-0000-000000000000",
  "old_sha256": "64-character lowercase SHA-256 hash",
  "new_sha256": "64-character lowercase SHA-256 hash",
  "new_body_file": "/absolute/path/to/new-body.txt"
}
```

Keep credentials and webhook secrets out of the manifest and body file.
Run `plan-body` before `apply-body`:

```bash
node scripts/jira-automation.cjs plan-body /absolute/path/update.json
node scripts/jira-automation.cjs apply-body /absolute/path/update.json
```

The helper reads the current rule before each command.
It requires the exact UUID, name, state, component ID, and old body hash.
It updates only the selected `customBody` value.
After the write, it reads the saved rule and compares all writable fields.
If this comparison fails, report an uncertain saved state and stop.
Remove the temporary manifest after a valid result.

## API reference

The helper uses this official endpoint:

```text
https://api.atlassian.com/automation/public/jira/{cloudId}/rest/v1/rule
```

Use the [Atlassian rule-management reference](https://developer.atlassian.com/cloud/automation/rest/api-group-rule-management/) if the API contract changes.
