---
name: azure-insights-tickets
description: Draft and, after explicit approval, create Jira bug tickets from grouped exceptions in the law-prod Azure Application Insights resource.
---

# Azure Insights Tickets

Use `$azure-insights` to gather the data. This skill converts exception evidence into reviewable Jira bug-ticket drafts. It does not create tickets before the user approves the exact draft set.

## Collect and group evidence

Query `law-prod` in `rg-observability`. If the component is absent, use the `$azure-insights` global component search.

Use the user-provided time window. If the user does not provide one, query the seven days before the current time. State the exact UTC start and end times.

Group repeated exceptions into actionable bug candidates. Use exception type, normalized message, operation, cloud role, deployment version, and first and last occurrence as grouping evidence. Do not create one draft for every telemetry row.

For each candidate, query related requests, dependencies, and traces where an operation ID or time correlation exists. Redact secrets, identifiers, request bodies, and tokens. State when a conclusion is only a correlation.

Discard or clearly label expected, handled, obsolete, and non-actionable exceptions. Retain the evidence that explains this decision.

## Prepare ticket drafts

Use `$twg` and `$twg-jira` to find the Jira site, likely project, permitted bug work type, current user, and duplicate candidates. Use read-only Jira commands at this stage.

Infer the Jira project from the `law` repository naming, related existing tickets, and available Jira projects. This is a guess. Show the selected project, alternatives, and confidence in the review list. Do not present a guess as a confirmed project.

Search the selected project for duplicates before the review. If a matching open ticket exists, list it as a duplicate candidate. Do not draft a new ticket unless the user asks for one despite the match.

Draft one ticket per distinct, actionable candidate. Each draft must include:

- A concise bug summary.
- The guessed Jira project and confidence.
- Work type `Bug`, if that type exists in the selected project.
- Assignee `Unassigned`.
- Reporter as the authenticated Jira user.
- Status `Inbox`.
- Label `azure-insights`.
- The count, first occurrence, last occurrence, affected operation or component, and impact.
- Redacted exception details and relevant request, dependency, or trace evidence.
- Reproduction or investigation steps that a human or agent can use.
- A clear uncertainty section and a suggested first action.

Start every description with an information panel. Use the Jira content format that live command help supports. The panel must state that Azure Application Insights data and an AI system generated the ticket draft.

End every externally visible description with this line:

```text
_Posted by Codex, an AI assistant, on behalf of Bart Steensma._
```

## Review gate

List every proposed ticket before any Jira write. Include the full summary, project guess, assignee, reporter, status, duplicate assessment, evidence summary, uncertainties, and proposed description.

Ask the user to correct the drafts or approve the exact ticket set. Treat an approval as valid only when it clearly identifies the presented drafts. Do not create tickets after a vague request such as "looks good" if the draft set changed.

## Create after approval

Before the write, use live `twg` help and create-field metadata for the selected project and work type. Do not guess field IDs, allowed values, an account ID, or a workflow transition.

Verify that the project can create a Bug with the initial `Inbox` status. If Jira requires a transition, discover it and its required fields before the write. If the status cannot become Inbox, stop and report the configuration gap.

Set the assignee to unassigned only if the project permits it. Set the reporter to the authenticated Jira user when the create metadata permits it. If Jira sets the reporter automatically, verify that it is the authenticated user after creation.

Add the `azure-insights` label to every approved ticket. Use the label field returned by create metadata. Do not remove existing labels unless the user explicitly asks.

Create only the approved drafts. Read back each work item. Verify its project, work type, assignee, reporter, status, label, description, and Jira key. Report each created ticket and any verification failure.
