---
name: azure-insights
description: Investigate Azure Application Insights telemetry for an application, repository, incident, or time window. Use for read-only production or development telemetry analysis, not Azure resource changes.
---

# Azure Insights

Use the authenticated `az` CLI to obtain evidence from Application Insights. The available data includes development and production resources, with `rg-observability` as the usual location.

## Scope and safety

Read telemetry only. Do not change Azure resources, alert rules, retention, access, or diagnostic settings.

Collect the least data that answers the request. Do not put connection strings, access tokens, cookies, full user identifiers, or other sensitive values in the result. Redact them if they occur in telemetry.

Do not create or update Jira work items unless the user explicitly asks. When the requested output is a Jira triage, use the telemetry as evidence and follow the Jira workflow that applies to the request.

## Find the component

First, list Application Insights components in `rg-observability`:

```sh
az monitor app-insights component show --resource-group rg-observability \
  --query '[].{name:name,appId:appId,workspace:workspaceResourceId,location:location}' -o table
```

Interpret the application name as the most likely repository name. Treat this as a candidate, not proof. Match meaningful name parts and environment suffixes such as `dev`, `development`, `prod`, or `production`. State the inferred repository and confidence when the mapping is ambiguous.

Select the environment named by the user. Ask only when the request does not identify an environment and the answer can materially change the conclusion. For an incident with no environment, examine production first and state that choice.

If no suitable component exists in that group, search each accessible subscription without changing the CLI default subscription:

```sh
az account list --all --query '[?state==`Enabled`].id' -o tsv
az resource list --subscription <subscription-id> \
  --resource-type Microsoft.Insights/components \
  --query '[].{name:name,resourceGroup:resourceGroup,id:id}' -o table
```

Use the component resource ID with `--ids` when names repeat across resource groups.

## Query and assess

Use a bounded time window. Start with the reported incident window. If none is given, use the last 24 hours and say so. Expand the range only when the first result needs context.

Run queries with the component identity:

```sh
az monitor app-insights query --ids <component-resource-id> \
  --analytics-query '<KQL>' --start-time '<UTC timestamp>' --end-time '<UTC timestamp>' -o json
```

Use the standard Application Insights tables: `requests`, `exceptions`, `traces`, and `dependencies`. The table can vary for workspace-based components. If a table fails, report the failure and query an available related table instead.

Read [KQL query patterns](references/kql.md) when you need error, request, dependency, trace, comparison, or correlation queries.

Separate observations from conclusions. Include the selected component, environment, time window, query purpose, key counts or rates, and representative redacted evidence. Do not call correlation a cause without evidence.

For an issue triage, identify the user impact, onset, frequency, affected operation or version, related dependency failures, and evidence that supports or weakens the issue report. State clear next actions and uncertainty.
