# KQL query patterns

Replace placeholders before you run a query. Use UTC timestamps. Filter rows before you summarize them. Limit detail rows to a small, relevant result set.

## Errors by type

```kql
exceptions
| where timestamp between (datetime(<start-utc>) .. datetime(<end-utc>))
| summarize count() by type, outerMessage, operation_Name, cloud_RoleName
| top 20 by count_ desc
```

## Failed requests

```kql
requests
| where timestamp between (datetime(<start-utc>) .. datetime(<end-utc>))
| where success == false or toint(resultCode) >= 500
| summarize failures=count(), users=dcount(user_Id) by name, resultCode, operation_Name, cloud_RoleName
| order by failures desc
```

## Error rate over time

```kql
requests
| where timestamp between (datetime(<start-utc>) .. datetime(<end-utc>))
| summarize total=count(), failed=countif(success == false or toint(resultCode) >= 500) by bin(timestamp, 15m)
| extend failureRate=round(100.0 * failed / total, 2)
| order by timestamp asc
```

## Slow or failed dependencies

```kql
dependencies
| where timestamp between (datetime(<start-utc>) .. datetime(<end-utc>))
| where success == false or duration > 2s
| summarize calls=count(), failures=countif(success == false), p95=percentile(duration, 95) by target, type, name, resultCode
| order by failures desc, p95 desc
```

## Relevant traces

```kql
traces
| where timestamp between (datetime(<start-utc>) .. datetime(<end-utc>))
| where severityLevel >= 3 or message has_cs "<search-term>"
| project timestamp, severityLevel, message, operation_Id, operation_Name, cloud_RoleName
| take 100
```

## Correlate one operation

Use the `operation_Id` from a relevant request, exception, or trace. Do not include sensitive custom dimensions in the output.

```kql
union requests, exceptions, dependencies, traces
| where operation_Id == "<operation-id>"
| project timestamp, itemType, name, message, type, target, resultCode, success, duration, operation_Name
| order by timestamp asc
```

## Compare before and during an incident

```kql
requests
| where timestamp between (datetime(<baseline-start>) .. datetime(<incident-end>))
| extend period=iff(timestamp between (datetime(<incident-start>) .. datetime(<incident-end>)), "incident", "baseline")
| summarize total=count(), failed=countif(success == false or toint(resultCode) >= 500), p95=percentile(duration, 95) by period, name
| extend failureRate=round(100.0 * failed / total, 2)
| order by name asc, period asc
```
