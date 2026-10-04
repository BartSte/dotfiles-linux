---
name: azure-insights
description: Investigate Azure Application Insights components and Log Analytics workspaces for an application, repository, incident, or time window. Use for read-only telemetry analysis, not Azure resource changes.
---

# Azure Insights

Use the authenticated `az` CLI to obtain evidence from Application Insights components or Log Analytics workspaces. The usual resource group is `rg-observability`.

## Scope and safety

Read telemetry only. Do not change Azure resources, alert rules, retention, access, or diagnostic settings.

Collect the least data that answers the request. Do not put connection strings, access tokens, cookies, full user identifiers, or other sensitive values in the result. Redact them if they occur in telemetry.

Do not create or update Jira work items unless the user explicitly asks. When the requested output is a Jira triage, use the telemetry as evidence and follow the Jira workflow that applies to the request.

## Find the telemetry resource

First, check both resource types in `rg-observability`. A named telemetry source can be a workspace rather than an Application Insights component. For example, `law-prod` is a Log Analytics workspace that contains telemetry from several components.

```sh
az resource list --resource-group rg-observability \
  --resource-type Microsoft.Insights/components \
  --query '[].{name:name,id:id}' -o table
az resource list --resource-group rg-observability \
  --resource-type Microsoft.OperationalInsights/workspaces \
  --query '[].{name:name,id:id}' -o table
```

For a workspace, use `_ResourceId` and `AppRoleName` in telemetry to identify the emitting component. Do not infer an application or repository from the workspace name alone. For a component, treat a name match with a repository as a candidate, not proof. Match meaningful name parts and environment suffixes such as `dev` and `prod`.

Select the environment named by the user. Ask only when the request does not identify an environment and the answer can materially change the conclusion. For an incident with no environment, examine production first and state that choice.

If neither resource type matches in that group, search both types in each accessible subscription without changing the CLI default subscription:

```sh
az account list --all --query '[?state==`Enabled`].id' -o tsv
az resource list --subscription <subscription-id> \
  --resource-type Microsoft.Insights/components \
  --query '[].{name:name,resourceGroup:resourceGroup,id:id}' -o table
az resource list --subscription <subscription-id> \
  --resource-type Microsoft.OperationalInsights/workspaces \
  --query '[].{name:name,resourceGroup:resourceGroup,id:id}' -o table
```

Use the component resource ID with `--ids` when names repeat across resource groups.

## Query and assess

Use a bounded time window. Start with the reported incident window. If none is given, use the last 24 hours and say so. Expand the range only when the first result needs context.

For an Application Insights component, query its resource ID:

```sh
az monitor app-insights query --ids <component-resource-id> \
  --analytics-query '<KQL>' --start-time '<UTC timestamp>' --end-time '<UTC timestamp>' -o json
```

For a Log Analytics workspace, get its customer ID and query its workspace tables. Include the UTC bounds in KQL:

```sh
az monitor log-analytics workspace show --resource-group <resource-group> \
  --workspace-name <workspace-name> --query customerId -o tsv
az monitor log-analytics query --workspace <workspace-customer-id> \
  --analytics-query '<bounded KQL>' -o json
```

Use `requests`, `exceptions`, `traces`, and `dependencies` for component queries. Use `AppRequests`, `AppExceptions`, `AppTraces`, and `AppDependencies` with `TimeGenerated` for workspace queries. Check the schema when a field or table differs. Do not treat an unresolved table name as proof that telemetry is absent.

Use an operation ID for correlation only when it is meaningful. A repeated all-zero ID is a placeholder. In that case, compare role, component, and time. Label the result as correlation. Project only fields needed for the question. Raw messages, stack traces, paths, and custom dimensions can contain identifiers.

Read [KQL query patterns](references/kql.md) when you need error, request, dependency, trace, comparison, or correlation queries. It includes workspace patterns.

Separate observations from conclusions. Include the selected resource, emitting component or role, environment, time window, query purpose, key counts or rates, and representative redacted evidence. A DNS lookup failure alone does not prove that a device had no internet access.

For an issue triage, identify the user impact, onset, frequency, affected operation or version, related dependency failures, and evidence that supports or weakens the issue report. State clear next actions and uncertainty.
