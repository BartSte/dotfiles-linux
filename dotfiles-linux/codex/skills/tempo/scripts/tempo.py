#!/usr/bin/env python3
"""Create and verify Tempo worklogs through the Jira and Tempo APIs."""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import subprocess
import sys
import time
from collections.abc import Iterable, Sequence
from dataclasses import dataclass, replace
from datetime import date, datetime, timedelta
from datetime import time as datetime_time
from pathlib import Path
from typing import TypeAlias
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

JsonScalar: TypeAlias = str | int | float | bool | None
JsonValue: TypeAlias = JsonScalar | list["JsonValue"] | dict[str, "JsonValue"]

DEFAULT_JIRA_BASE_URL = "https://fleetcleaner.atlassian.net"
DEFAULT_TEMPO_BASE_URL = "https://api.tempo.io/4"
DEFAULT_TIMEZONE = "Europe/Berlin"
ACCOUNT_ATTRIBUTE_KEY = "_Account_"
ACCOUNTS_PATH = (
    Path(__file__).resolve().parent.parent / "references" / "accounts.json"
)
ISSUE_PATTERN = re.compile(
    r"^(?P<prefix>[A-Z][A-Z0-9_]*)-(?P<number>[1-9][0-9]*)$"
)
WORK_BLOCKS = (
    (datetime_time(8, 30), datetime_time(10, 30)),
    (datetime_time(10, 30), datetime_time(12, 30)),
    (datetime_time(13, 30), datetime_time(15, 30)),
    (datetime_time(15, 30), datetime_time(17, 30)),
)


class TempoClientError(RuntimeError):
    """An expected error in configuration, validation, or an API call."""


@dataclass(frozen=True)
class AccountMapping:
    """A Jira prefix to Tempo account mapping."""

    prefix: str
    key: str
    name: str


@dataclass(frozen=True)
class WorklogEntry:
    """One requested worklog entry."""

    issue: str
    start: datetime
    duration_minutes: int
    description: str
    account: AccountMapping

    @property
    def jira_started(self) -> str:
        """Return the Jira timestamp representation."""
        return self.start.strftime("%Y-%m-%dT%H:%M:%S.000%z")

    @property
    def signature(self) -> tuple[str, str, int, str]:
        """Return fields that identify a matching worklog."""
        return (
            self.issue,
            self.start.strftime("%Y-%m-%dT%H:%M"),
            self.duration_minutes * 60,
            self.description,
        )


@dataclass(frozen=True)
class WorklogMatch:
    """A Jira worklog that matches a requested entry."""

    entry: WorklogEntry
    jira_worklog_id: int
    created: bool


class JsonApi:
    """A small JSON HTTP client with fixed authorization headers."""

    def __init__(self, base_url: str, authorization: str) -> None:
        """Initialize the client with its base URL and authorization value."""
        self._base_url = base_url.rstrip("/")
        self._authorization = authorization

    def request(
        self,
        method: str,
        path: str,
        *,
        body: JsonValue | None = None,
        query: dict[str, str | int] | None = None,
    ) -> JsonValue | None:
        """Send a request and decode its optional JSON response."""
        url = f"{self._base_url}/{path.lstrip('/')}"
        if query:
            url = f"{url}?{urlencode(query)}"
        data = None if body is None else json.dumps(body).encode("utf-8")
        request = Request(
            url,
            data=data,
            method=method,
            headers={
                "Accept": "application/json",
                "Authorization": self._authorization,
                "Content-Type": "application/json",
            },
        )
        try:
            with urlopen(request, timeout=30) as response:  # noqa: S310
                raw = response.read()
        except HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            raise TempoClientError(
                f"{method} {path} failed with HTTP {error.code}: {detail}"
            ) from error
        except URLError as error:
            raise TempoClientError(
                f"{method} {path} failed: {error.reason}"
            ) from error
        if not raw:
            return None
        try:
            value: JsonValue = json.loads(raw)
        except json.JSONDecodeError as error:
            raise TempoClientError(
                f"{method} {path} returned invalid JSON"
            ) from error
        return value


class JiraApi:
    """Jira operations required for Tempo worklogs."""

    def __init__(self, client: JsonApi) -> None:
        """Initialize the Jira API wrapper."""
        self._client = client

    def current_account_id(self) -> str:
        """Return the authenticated user's Jira account ID."""
        payload = require_object(
            self._client.request("GET", "/rest/api/3/myself")
        )
        return require_string(payload, "accountId")

    def issue_worklogs(self, issue: str) -> list[dict[str, JsonValue]]:
        """Return all worklogs for one issue."""
        worklogs: list[dict[str, JsonValue]] = []
        start_at = 0
        while True:
            payload = require_object(
                self._client.request(
                    "GET",
                    f"/rest/api/3/issue/{issue}/worklog",
                    query={"startAt": start_at, "maxResults": 1000},
                )
            )
            page = require_object_list(payload, "worklogs")
            worklogs.extend(page)
            total = require_integer(payload, "total")
            start_at += len(page)
            if start_at >= total or not page:
                return worklogs

    def create_worklog(self, entry: WorklogEntry) -> int:
        """Create one Jira worklog and return its ID."""
        payload = require_object(
            self._client.request(
                "POST",
                f"/rest/api/3/issue/{entry.issue}/worklog",
                body={
                    "comment": adf_comment(entry.description),
                    "started": entry.jira_started,
                    "timeSpentSeconds": entry.duration_minutes * 60,
                },
            )
        )
        return integer_value(payload.get("id"), "Jira worklog id")


class TempoApi:
    """Tempo operations required to attach and verify Account values."""

    def __init__(self, client: JsonApi) -> None:
        """Initialize the Tempo API wrapper."""
        self._client = client

    def accounts(self) -> list[dict[str, JsonValue]]:
        """Return the available Tempo accounts."""
        payload = require_object(
            self._client.request("GET", "/accounts", query={"limit": 1000})
        )
        return require_object_list(payload, "results")

    def map_jira_worklogs(
        self,
        jira_worklog_ids: Sequence[int],
        *,
        attempts: int = 1,
    ) -> dict[int, int]:
        """Map Jira worklog IDs to Tempo IDs with synchronization retries."""
        if not jira_worklog_ids:
            return {}
        wanted = set(jira_worklog_ids)
        mappings: dict[int, int] = {}
        for attempt in range(attempts):
            payload = self._client.request(
                "POST",
                "/worklogs/jira-to-tempo",
                body={"jiraWorklogIds": sorted(wanted)},
            )
            mappings.update(extract_worklog_mappings(payload))
            if wanted <= mappings.keys():
                return {jira_id: mappings[jira_id] for jira_id in wanted}
            if attempt + 1 < attempts:
                time.sleep(min(2**attempt, 5))
        missing = ", ".join(
            str(value) for value in sorted(wanted - mappings.keys())
        )
        raise TempoClientError(
            "Tempo did not map these Jira worklog IDs: "
            f"{missing}. Retry after Jira-to-Tempo synchronization completes."
        )

    def account_values(
        self, tempo_worklog_ids: Sequence[int]
    ) -> dict[int, str]:
        """Return existing Account values, keyed by Tempo worklog ID."""
        if not tempo_worklog_ids:
            return {}
        payload = self._client.request(
            "POST",
            "/worklogs/work-attribute-values/search",
            body={"tempoWorklogIds": list(tempo_worklog_ids)},
        )
        return extract_account_values(payload)

    def create_account_values(self, assignments: dict[int, str]) -> None:
        """Create missing Account values."""
        if not assignments:
            return
        body: list[JsonValue] = [
            {
                "tempoWorklogId": tempo_id,
                "attributeValues": [
                    {"key": ACCOUNT_ATTRIBUTE_KEY, "value": account_key}
                ],
            }
            for tempo_id, account_key in sorted(assignments.items())
        ]
        self._client.request(
            "POST", "/worklogs/work-attribute-values", body=body
        )


def require_object(value: JsonValue | None) -> dict[str, JsonValue]:
    """Validate that an API value is an object."""
    if not isinstance(value, dict):
        raise TempoClientError("The API response is not a JSON object")
    return value


def require_string(value: dict[str, JsonValue], key: str) -> str:
    """Get a required string from an object."""
    result = value.get(key)
    if not isinstance(result, str) or not result:
        raise TempoClientError(f"The API response has no valid {key}")
    return result


def require_integer(value: dict[str, JsonValue], key: str) -> int:
    """Get a required integer from an object."""
    return integer_value(value.get(key), key)


def integer_value(value: JsonValue | None, label: str) -> int:
    """Convert an integer or numeric string to an integer."""
    if isinstance(value, bool):
        raise TempoClientError(f"{label} is not an integer")
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.isdigit():
        return int(value)
    raise TempoClientError(f"{label} is not an integer")


def require_object_list(
    value: dict[str, JsonValue], key: str
) -> list[dict[str, JsonValue]]:
    """Get a required list of objects from an object."""
    result = value.get(key)
    if not isinstance(result, list) or any(
        not isinstance(item, dict) for item in result
    ):
        raise TempoClientError(f"The API response has no valid {key} list")
    return [item for item in result if isinstance(item, dict)]


def rbw_get(item: str, field: str | None = None) -> str:
    """Read one secret value from rbw without displaying it."""
    command = ["rbw", "get"]
    if field:
        command.extend(["--field", field])
    command.append(item)
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise TempoClientError("rbw is not installed") from error
    except subprocess.CalledProcessError as error:
        raise TempoClientError(
            f"Could not read {item} from rbw. Unlock the vault and retry."
        ) from error
    secret = result.stdout.strip()
    if not secret:
        raise TempoClientError(f"rbw returned an empty value for {item}")
    return secret


def make_apis() -> tuple[JiraApi, TempoApi]:
    """Create authenticated Jira and Tempo API clients."""
    jira_email = os.environ.get("JIRA_EMAIL") or rbw_get(
        "atlassian_token", field="username"
    )
    jira_token = os.environ.get("JIRA_API_TOKEN") or rbw_get("atlassian_token")
    tempo_token = os.environ.get("TEMPO_API_TOKEN") or rbw_get(
        "atlassian_tempo_token"
    )
    basic_value = base64.b64encode(
        f"{jira_email}:{jira_token}".encode("utf-8")
    ).decode("ascii")
    jira_client = JsonApi(
        os.environ.get("JIRA_BASE_URL", DEFAULT_JIRA_BASE_URL),
        f"Basic {basic_value}",
    )
    tempo_client = JsonApi(
        os.environ.get("TEMPO_API_BASE_URL", DEFAULT_TEMPO_BASE_URL),
        f"Bearer {tempo_token}",
    )
    return JiraApi(jira_client), TempoApi(tempo_client)


def load_account_mappings(
    path: Path = ACCOUNTS_PATH,
) -> dict[str, AccountMapping]:
    """Load and validate Jira-prefix-to-account mappings."""
    try:
        value: JsonValue = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise TempoClientError(
            f"Account mapping file not found: {path}"
        ) from error
    except json.JSONDecodeError as error:
        raise TempoClientError(
            f"Account mapping file is invalid: {error}"
        ) from error
    root = require_object(value)
    mappings: dict[str, AccountMapping] = {}
    for raw_prefix, raw_mapping in root.items():
        prefix = raw_prefix.upper()
        if prefix != raw_prefix or not re.fullmatch(r"[A-Z][A-Z0-9_]*", prefix):
            raise TempoClientError(
                f"Invalid account mapping prefix: {raw_prefix}"
            )
        mapping = require_object(raw_mapping)
        mappings[prefix] = AccountMapping(
            prefix=prefix,
            key=require_string(mapping, "key"),
            name=require_string(mapping, "name"),
        )
    return mappings


def load_manifest(
    path: Path, mappings: dict[str, AccountMapping]
) -> list[WorklogEntry]:
    """Load and validate a one-day manifest."""
    try:
        value: JsonValue = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise TempoClientError(f"Manifest not found: {path}") from error
    except json.JSONDecodeError as error:
        raise TempoClientError(f"Manifest is invalid JSON: {error}") from error
    root = require_object(value)
    raw_date = require_string(root, "date")
    try:
        work_date = date.fromisoformat(raw_date)
    except ValueError as error:
        raise TempoClientError("Manifest date must use YYYY-MM-DD") from error
    timezone_name = root.get("timezone", DEFAULT_TIMEZONE)
    if not isinstance(timezone_name, str) or not timezone_name:
        raise TempoClientError("Manifest timezone must be a non-empty string")
    try:
        timezone = ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError as error:
        raise TempoClientError(f"Unknown time zone: {timezone_name}") from error
    raw_entries = root.get("entries")
    if not isinstance(raw_entries, list) or not raw_entries:
        raise TempoClientError("Manifest entries must be a non-empty list")
    entries: list[WorklogEntry] = []
    unknown_prefixes: set[str] = set()
    for index, raw_entry in enumerate(raw_entries, start=1):
        entry_object = require_object(raw_entry)
        issue = require_string(entry_object, "issue").upper()
        match = ISSUE_PATTERN.fullmatch(issue)
        if match is None:
            raise TempoClientError(
                f"Entry {index} has an invalid Jira issue key: {issue}"
            )
        prefix = match.group("prefix")
        account = mappings.get(prefix)
        if account is None:
            unknown_prefixes.add(prefix)
            continue
        raw_start = require_string(entry_object, "start")
        try:
            start_time = datetime_time.fromisoformat(raw_start)
        except ValueError as error:
            raise TempoClientError(
                f"Entry {index} start must use a 24-hour local time"
            ) from error
        if (
            start_time.second
            or start_time.microsecond
            or start_time.tzinfo is not None
        ):
            raise TempoClientError(f"Entry {index} start must use HH:MM")
        duration = integer_value(
            entry_object.get("duration_minutes"),
            f"Entry {index} duration_minutes",
        )
        if duration <= 0:
            raise TempoClientError(f"Entry {index} duration must be positive")
        description = require_string(entry_object, "description").strip()
        start = datetime.combine(work_date, start_time, tzinfo=timezone)
        if start + timedelta(minutes=duration) > datetime.combine(
            work_date + timedelta(days=1), datetime_time.min, tzinfo=timezone
        ):
            raise TempoClientError(
                f"Entry {index} extends beyond the manifest date"
            )
        entries.append(
            WorklogEntry(
                issue=issue,
                start=start,
                duration_minutes=duration,
                description=description,
                account=account,
            )
        )
    if unknown_prefixes:
        prefixes = ", ".join(sorted(unknown_prefixes))
        raise TempoClientError(
            f"No Tempo account mapping exists for Jira prefix: {prefixes}. "
            "Use the Tempo accounts and Jira project context to resolve it. "
            "If the mapping is uncertain, ask the user before any API write."
        )
    return expand_occupied_blocks(entries)


def validate_manifest_entries(entries: Sequence[WorklogEntry]) -> None:
    """Reject duplicate or overlapping manifest entries."""
    signatures: set[tuple[str, str, int, str]] = set()
    for entry in entries:
        if entry.signature in signatures:
            raise TempoClientError(
                f"Duplicate manifest entry: {entry.issue} at {clock(entry)}"
            )
        signatures.add(entry.signature)
    ordered = sorted(entries, key=lambda item: item.start)
    for previous, current in zip(ordered, ordered[1:]):
        previous_end = previous.start + timedelta(
            minutes=previous.duration_minutes
        )
        if current.start < previous_end:
            raise TempoClientError(
                "Manifest entries overlap: "
                f"{previous.issue} and {current.issue}"
            )


def expand_occupied_blocks(
    entries: Sequence[WorklogEntry],
) -> list[WorklogEntry]:
    """Expand each occupied work block to its full two-hour range."""
    validate_manifest_entries(entries)
    entries_by_block: list[list[WorklogEntry]] = [[] for _ in WORK_BLOCKS]
    for entry in entries:
        segments = split_entry_across_blocks(entry)
        for block_index, segment in segments:
            entries_by_block[block_index].append(segment)

    expanded: list[WorklogEntry] = []
    for block_entries, (raw_block_start, raw_block_end) in zip(
        entries_by_block, WORK_BLOCKS
    ):
        if not block_entries:
            continue
        ordered = sorted(block_entries, key=lambda item: item.start)
        work_date = ordered[0].start.date()
        timezone = ordered[0].start.tzinfo
        block_start = datetime.combine(
            work_date, raw_block_start, tzinfo=timezone
        )
        block_end = datetime.combine(work_date, raw_block_end, tzinfo=timezone)
        for index, entry in enumerate(ordered):
            expanded_start = block_start if index == 0 else entry.start
            expanded_end = (
                ordered[index + 1].start
                if index + 1 < len(ordered)
                else block_end
            )
            duration = int(
                (expanded_end - expanded_start).total_seconds() // 60
            )
            expanded.append(
                replace(
                    entry,
                    start=expanded_start,
                    duration_minutes=duration,
                )
            )
    validate_manifest_entries(expanded)
    return expanded


def split_entry_across_blocks(
    entry: WorklogEntry,
) -> list[tuple[int, WorklogEntry]]:
    """Return the parts of an entry that intersect fixed work blocks."""
    work_date = entry.start.date()
    timezone = entry.start.tzinfo
    entry_end = entry.start + timedelta(minutes=entry.duration_minutes)
    segments: list[tuple[int, WorklogEntry]] = []
    for index, (raw_block_start, raw_block_end) in enumerate(WORK_BLOCKS):
        block_start = datetime.combine(
            work_date, raw_block_start, tzinfo=timezone
        )
        block_end = datetime.combine(work_date, raw_block_end, tzinfo=timezone)
        segment_start = max(entry.start, block_start)
        segment_end = min(entry_end, block_end)
        if segment_start >= segment_end:
            continue
        duration = int((segment_end - segment_start).total_seconds() // 60)
        segments.append(
            (
                index,
                replace(
                    entry,
                    start=segment_start,
                    duration_minutes=duration,
                ),
            )
        )
    if segments:
        return segments
    raise TempoClientError(
        f"Entry {entry.issue} at {clock(entry)} is outside the fixed "
        "work blocks"
    )


def adf_comment(text: str) -> dict[str, JsonValue]:
    """Create an Atlassian Document Format comment."""
    return {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": text}],
            }
        ],
    }


def adf_text(value: JsonValue | None) -> str:
    """Extract plain text from an Atlassian Document Format value."""
    fragments: list[str] = []

    def visit(node: JsonValue | None) -> None:
        if isinstance(node, dict):
            text_value = node.get("text")
            if isinstance(text_value, str):
                fragments.append(text_value)
            for child in node.values():
                visit(child)
        elif isinstance(node, list):
            for child in node:
                visit(child)

    visit(value)
    return "".join(fragments)


def find_matching_worklog(
    entry: WorklogEntry,
    worklogs: Iterable[dict[str, JsonValue]],
    account_id: str,
) -> int | None:
    """Find one worklog that exactly matches a manifest entry."""
    matches: list[int] = []
    expected_start = entry.start.strftime("%Y-%m-%dT%H:%M")
    for worklog in worklogs:
        author = worklog.get("author")
        if (
            not isinstance(author, dict)
            or author.get("accountId") != account_id
        ):
            continue
        started = worklog.get("started")
        if not isinstance(started, str) or not started.startswith(
            expected_start
        ):
            continue
        try:
            seconds = integer_value(
                worklog.get("timeSpentSeconds"), "timeSpentSeconds"
            )
        except TempoClientError:
            continue
        if seconds != entry.duration_minutes * 60:
            continue
        if adf_text(worklog.get("comment")) != entry.description:
            continue
        matches.append(integer_value(worklog.get("id"), "Jira worklog id"))
    if len(matches) > 1:
        raise TempoClientError(
            f"More than one matching Jira worklog exists for {entry.issue} "
            f"at {clock(entry)}"
        )
    return matches[0] if matches else None


def walk_objects(value: JsonValue | None) -> Iterable[dict[str, JsonValue]]:
    """Yield every JSON object in a nested response."""
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk_objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_objects(child)


def extract_worklog_mappings(value: JsonValue | None) -> dict[int, int]:
    """Extract Jira-to-Tempo worklog mappings from a response."""
    mappings: dict[int, int] = {}
    for item in walk_objects(value):
        if "jiraWorklogId" not in item or "tempoWorklogId" not in item:
            continue
        jira_id = integer_value(item.get("jiraWorklogId"), "jiraWorklogId")
        tempo_id = integer_value(item.get("tempoWorklogId"), "tempoWorklogId")
        mappings[jira_id] = tempo_id
    return mappings


def extract_account_values(value: JsonValue | None) -> dict[int, str]:
    """Extract Account values from a work-attribute search response."""
    values: dict[int, str] = {}
    for item in walk_objects(value):
        raw_id = item.get("tempoWorklogId", item.get("worklogId"))
        if raw_id is None:
            continue
        try:
            tempo_id = integer_value(raw_id, "tempoWorklogId")
        except TempoClientError:
            continue
        for list_key in ("attributeValues", "workAttributeValues"):
            attributes = item.get(list_key)
            if not isinstance(attributes, list):
                continue
            for attribute in attributes:
                if not isinstance(attribute, dict):
                    continue
                if attribute.get("key") != ACCOUNT_ATTRIBUTE_KEY:
                    continue
                account_key = attribute.get("value")
                if isinstance(account_key, str):
                    values[tempo_id] = account_key
    return values


def validate_remote_accounts(
    mappings: Iterable[AccountMapping], accounts: Sequence[dict[str, JsonValue]]
) -> None:
    """Validate that each configured account key exists in Tempo."""
    by_key = {
        item["key"]: item
        for item in accounts
        if isinstance(item.get("key"), str)
    }
    for mapping in mappings:
        account = by_key.get(mapping.key)
        if account is None:
            raise TempoClientError(
                f"Tempo account key {mapping.key} for prefix {mapping.prefix} "
                "does not exist"
            )
        remote_name = account.get("name")
        if isinstance(remote_name, str) and remote_name != mapping.name:
            print(
                f"Warning: account {mapping.key} is named {remote_name!r}, "
                f"not {mapping.name!r}.",
                file=sys.stderr,
            )


def match_existing_entries(
    jira: JiraApi, entries: Sequence[WorklogEntry], account_id: str
) -> list[WorklogMatch | None]:
    """Match each entry to an existing Jira worklog, if present."""
    by_issue: dict[str, list[dict[str, JsonValue]]] = {}
    for issue in dict.fromkeys(entry.issue for entry in entries):
        by_issue[issue] = jira.issue_worklogs(issue)
    return [
        (
            WorklogMatch(entry, jira_id, created=False)
            if (
                jira_id := find_matching_worklog(
                    entry, by_issue[entry.issue], account_id
                )
            )
            is not None
            else None
        )
        for entry in entries
    ]


def check_account_values(
    matches: Sequence[WorklogMatch],
    mappings: dict[int, int],
    values: dict[int, str],
) -> dict[int, str]:
    """Return missing values and reject incorrect existing values."""
    missing: dict[int, str] = {}
    for match in matches:
        tempo_id = mappings[match.jira_worklog_id]
        expected = match.entry.account.key
        current = values.get(tempo_id)
        if current is None:
            missing[tempo_id] = expected
        elif current != expected:
            raise TempoClientError(
                f"Tempo worklog {tempo_id} for {match.entry.issue} has Account "
                f"{current}, but {expected} is required. Correct it manually "
                "before retrying."
            )
    return missing


def verify_matches(
    tempo: TempoApi, matches: Sequence[WorklogMatch], *, attempts: int = 1
) -> dict[int, int]:
    """Map worklogs and verify their expected Account values."""
    jira_ids = [match.jira_worklog_id for match in matches]
    mappings = tempo.map_jira_worklogs(jira_ids, attempts=attempts)
    values = tempo.account_values(list(mappings.values()))
    missing = check_account_values(matches, mappings, values)
    if missing:
        details = ", ".join(str(value) for value in sorted(missing))
        raise TempoClientError(
            f"Tempo Account is missing from worklog IDs: {details}"
        )
    return mappings


def plan_command(manifest: Path) -> int:
    """Validate and display a manifest without API calls."""
    entries = load_manifest(manifest, load_account_mappings())
    print_entries(entries, heading="Plan")
    print(f"Total: {sum(entry.duration_minutes for entry in entries)} minutes")
    return 0


def accounts_command(query: str | None) -> int:
    """List Tempo accounts through a read-only API call."""
    _, tempo = make_apis()
    needle = query.casefold() if query else None
    rows: list[tuple[str, str]] = []
    for account in tempo.accounts():
        key = account.get("key")
        name = account.get("name")
        if not isinstance(key, str) or not isinstance(name, str):
            continue
        haystack = f"{key} {name}".casefold()
        if needle is None or needle in haystack:
            rows.append((key, name))
    for key, name in sorted(rows, key=lambda row: row[1].casefold()):
        print(f"{key}\t{name}")
    if not rows:
        print("No matching Tempo accounts found.")
        return 1
    return 0


def verify_command(manifest: Path) -> int:
    """Verify manifest entries without changing Jira or Tempo."""
    entries = load_manifest(manifest, load_account_mappings())
    jira, tempo = make_apis()
    validate_remote_accounts(
        {entry.account for entry in entries}, tempo.accounts()
    )
    account_id = jira.current_account_id()
    optional_matches = match_existing_entries(jira, entries, account_id)
    missing_entries = [
        entry
        for entry, match in zip(entries, optional_matches)
        if match is None
    ]
    if missing_entries:
        print_entries(missing_entries, heading="Missing Jira worklogs")
        return 1
    matches = [match for match in optional_matches if match is not None]
    mappings = verify_matches(tempo, matches)
    print_verified(matches, mappings)
    return 0


def apply_command(manifest: Path) -> int:
    """Create missing worklogs, assign Accounts, and verify the result."""
    entries = load_manifest(manifest, load_account_mappings())
    jira, tempo = make_apis()
    validate_remote_accounts(
        {entry.account for entry in entries}, tempo.accounts()
    )
    account_id = jira.current_account_id()
    optional_matches = match_existing_entries(jira, entries, account_id)

    existing = [match for match in optional_matches if match is not None]
    if existing:
        existing_mappings = tempo.map_jira_worklogs(
            [match.jira_worklog_id for match in existing]
        )
        existing_values = tempo.account_values(list(existing_mappings.values()))
        check_account_values(existing, existing_mappings, existing_values)

    matches: list[WorklogMatch] = []
    for entry, match in zip(entries, optional_matches):
        if match is not None:
            matches.append(match)
            continue
        jira_id = jira.create_worklog(entry)
        print(f"Created Jira worklog {jira_id} for {entry.issue}.")
        matches.append(WorklogMatch(entry, jira_id, created=True))

    mappings = tempo.map_jira_worklogs(
        [match.jira_worklog_id for match in matches], attempts=8
    )
    current_values = tempo.account_values(list(mappings.values()))
    missing_values = check_account_values(matches, mappings, current_values)
    if missing_values:
        tempo.create_account_values(missing_values)
    final_values = tempo.account_values(list(mappings.values()))
    remaining = check_account_values(matches, mappings, final_values)
    if remaining:
        details = ", ".join(str(value) for value in sorted(remaining))
        raise TempoClientError(
            f"Tempo did not persist Account values for worklog IDs: {details}"
        )
    print_verified(matches, mappings)
    return 0


def clock(entry: WorklogEntry) -> str:
    """Return a human-readable local clock value."""
    return entry.start.strftime("%Y-%m-%d %H:%M")


def print_entries(entries: Sequence[WorklogEntry], *, heading: str) -> None:
    """Print a compact entry table."""
    print(heading)
    for entry in entries:
        print(
            f"{clock(entry)}  {entry.duration_minutes:>4}m  {entry.issue:<12} "
            f"{entry.account.key:<14} {entry.description}"
        )


def print_verified(
    matches: Sequence[WorklogMatch], mappings: dict[int, int]
) -> None:
    """Print verified Jira and Tempo IDs."""
    print("Verified")
    for match in matches:
        state = "created" if match.created else "existing"
        tempo_id = mappings[match.jira_worklog_id]
        print(
            f"{clock(match.entry)}  {match.entry.duration_minutes:>4}m  "
            f"{match.entry.issue:<12} {match.entry.account.key:<14} "
            f"Jira {match.jira_worklog_id}  Tempo {tempo_id}  "
            f"{state}"
        )


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line parser."""
    parser = argparse.ArgumentParser(
        description="Create and verify Tempo worklogs through APIs."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    plan_parser = subparsers.add_parser(
        "plan", help="validate and display a manifest without API calls"
    )
    plan_parser.add_argument("manifest", type=Path)

    accounts_parser = subparsers.add_parser(
        "accounts", help="list Tempo accounts through a read-only API call"
    )
    accounts_parser.add_argument(
        "--query", help="filter by account key or name"
    )

    verify_parser = subparsers.add_parser(
        "verify", help="verify a manifest through read-only API calls"
    )
    verify_parser.add_argument("manifest", type=Path)

    apply_parser = subparsers.add_parser(
        "apply", help="create missing worklogs and Account values"
    )
    apply_parser.add_argument("manifest", type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Run the selected command."""
    arguments = build_parser().parse_args(argv)
    try:
        if arguments.command == "plan":
            return plan_command(arguments.manifest)
        if arguments.command == "accounts":
            return accounts_command(arguments.query)
        if arguments.command == "verify":
            return verify_command(arguments.manifest)
        if arguments.command == "apply":
            return apply_command(arguments.manifest)
        raise TempoClientError(f"Unknown command: {arguments.command}")
    except TempoClientError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
