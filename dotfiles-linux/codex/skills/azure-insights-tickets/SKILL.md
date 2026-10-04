---
name: azure-insights-tickets
description: Draft and, after explicit approval, create Jira bug tickets from grouped exceptions in the law-prod Log Analytics workspace.
---

# Azure Insights Tickets

Use `$azure-insights` to gather the data. This skill converts exception evidence into reviewable Jira bug-ticket drafts. It does not create tickets before the user approves the exact draft set.

## Collect and group evidence

Query the `law-prod` Log Analytics workspace in `rg-observability`. Its `AppExceptions` table includes events from several Application Insights components. Use `_ResourceId` and `AppRoleName` to separate them. If the workspace is absent, use the `$azure-insights` resource search.

Use the user-provided time window. If the user does not provide one, query the seven days before the current time. State the exact UTC start and end times.

Group repeated exceptions into actionable bug candidates. Use exception type, normalized message, operation, role, component resource ID, and deployment version. Record the first and last occurrence. Related exception rows can describe one failure. Do not count them as separate incidents without evidence.

For each candidate, query related requests, dependencies, and traces where an operation ID or time correlation exists. Treat repeated all-zero operation IDs as unusable. Redact secrets, identifiers, request bodies, paths with user names, and tokens before including telemetry in a draft. State when a conclusion is only a correlation.

Discard or clearly label expected, handled, obsolete, and non-actionable exceptions. A request to change the severity of an expected failure can still be an actionable bug. Retain the evidence that explains each decision.

## Prepare ticket drafts

Use `$twg` and `$twg-jira` to find the Jira site, likely project, permitted bug work type, current user, and duplicate candidates. Use read-only Jira commands at this stage.

Use a project that the user specifies. Otherwise, infer one from the emitting component, related existing tickets, and available Jira projects. Show the selected project, alternatives, and confidence in the review list. Do not present an inference as a confirmed project.

Search the selected project for duplicates before the review. If a matching open ticket exists, list it as a duplicate candidate. Do not draft a new ticket unless the user asks for one despite the match.

Draft one ticket per distinct, actionable candidate. Each draft must include:

- A concise bug summary.
- The selected Jira project. State whether the user specified it or it is an inference. Give confidence for an inference.
- Work type `Bug`, if that type exists in the selected project.
- Assignee `Unassigned`.
- Reporter as the authenticated Jira user.
- Status `Inbox`.
- Label `azure-insights`.
- The count, first occurrence, last occurrence, affected operation or component, and impact.
- Redacted exception details and relevant request, dependency, or trace evidence.
- Reproduction or investigation steps that a human or agent can use.
- A clear uncertainty section and a suggested first action.

Start every description with an information panel. The `twg jira workitem create` HTML format accepts `<div data-type="panel-info"><p>...</p></div>`. It converts this HTML to a Jira information panel. Do not use `class="panel"` or `data-panel-type="info"`. The CLI rejects those attributes. The panel must state that Azure Application Insights data and an AI system generated the ticket draft.

End every externally visible description with this line:

```text
_Posted by Codex (AI) for Bart Steensma._
```

## Review gate

List every proposed ticket before any Jira write. Include the full summary, project choice, assignee, reporter, status, duplicate assessment, evidence summary, uncertainties, and proposed description.

Ask the user to correct the drafts or approve the exact ticket set. Treat an approval as valid only when it clearly identifies the presented drafts. Do not create tickets after a vague request such as "looks good" if the draft set changed.

## Create after approval

Before the write, use live `twg` help and create-field metadata for the selected project and work type. Do not guess field IDs, allowed values, an account ID, or a workflow transition.

Verify that the project supports `Bug` and that its workflow can reach `Inbox`. If creation starts in another status, discover the new item's transition and required fields before changing it. If the status cannot become Inbox, stop and report the configuration gap.

The create metadata command can show only custom fields. Use the standard fields advertised by live `twg jira workitem create` help. Omit `--assignee` when the project permits unassigned items. Verify the result. Use `--reporter me` when permitted. Otherwise, verify the reporter that Jira sets automatically.

Add the `azure-insights` label to every approved ticket with the standard `--labels` option when create metadata does not list labels. Do not remove existing labels unless the user explicitly asks.

Create only the approved drafts. Read back each work item. Verify its project, work type, assignee, reporter, status, label, description, and Jira key. Report each created ticket and any verification failure.
