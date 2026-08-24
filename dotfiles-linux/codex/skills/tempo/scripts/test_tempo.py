#!/usr/bin/env python3
"""Unit tests for the Tempo API client."""

from __future__ import annotations

import json
import tempfile
import unittest
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import tempo


class TempoClientTest(unittest.TestCase):
    """Test deterministic validation and response parsing."""

    def setUp(self) -> None:
        """Create reusable account and worklog fixtures."""
        self.mapping = tempo.AccountMapping(
            prefix="FL", key="2025-001", name="Fleet Inspector Light"
        )
        self.entry = tempo.WorklogEntry(
            issue="FL-217",
            start=datetime(
                2026, 6, 30, 8, 45, tzinfo=ZoneInfo("Europe/Berlin")
            ),
            duration_minutes=30,
            description="Inspection Data Mapper",
            account=self.mapping,
        )

    def test_adf_round_trip(self) -> None:
        """Preserve text through Atlassian Document Format conversion."""
        self.assertEqual(
            tempo.adf_text(tempo.adf_comment("Inspection Data Mapper")),
            "Inspection Data Mapper",
        )

    def test_find_matching_worklog(self) -> None:
        """Find a Jira worklog that matches all identity fields."""
        worklog: dict[str, tempo.JsonValue] = {
            "id": "1234",
            "author": {"accountId": "me"},
            "started": "2026-06-30T08:45:00.000+0200",
            "timeSpentSeconds": 1800,
            "comment": tempo.adf_comment("Inspection Data Mapper"),
        }
        self.assertEqual(
            tempo.find_matching_worklog(self.entry, [worklog], "me"), 1234
        )

    def test_extract_worklog_mappings(self) -> None:
        """Extract numeric mappings from mixed numeric representations."""
        payload: tempo.JsonValue = {
            "results": [
                {"jiraWorklogId": "12", "tempoWorklogId": 34},
                {"jiraWorklogId": 56, "tempoWorklogId": "78"},
            ]
        }
        self.assertEqual(
            tempo.extract_worklog_mappings(payload), {12: 34, 56: 78}
        )

    def test_extract_account_values(self) -> None:
        """Extract the Account value from a nested Tempo response."""
        payload: tempo.JsonValue = {
            "results": [
                {
                    "tempoWorklogId": 34,
                    "workAttributeValues": [
                        {"key": "_Account_", "value": "2025-001"}
                    ],
                }
            ]
        }
        self.assertEqual(
            tempo.extract_account_values(payload), {34: "2025-001"}
        )

    def test_manifest_rejects_unknown_prefix_before_api_use(self) -> None:
        """Reject an unknown project prefix during local validation."""
        document = {
            "date": "2026-06-30",
            "entries": [
                {
                    "issue": "NEW-1",
                    "start": "09:00",
                    "duration_minutes": 30,
                    "description": "Unknown project",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            with self.assertRaisesRegex(
                tempo.TempoClientError, "No Tempo account"
            ):
                tempo.load_manifest(path, {"FL": self.mapping})

    def test_manifest_rejects_overlap(self) -> None:
        """Reject overlapping source suggestions."""
        second = tempo.WorklogEntry(
            issue="FL-218",
            start=datetime(2026, 6, 30, 9, 0, tzinfo=ZoneInfo("Europe/Berlin")),
            duration_minutes=30,
            description="Overlap",
            account=self.mapping,
        )
        with self.assertRaisesRegex(tempo.TempoClientError, "overlap"):
            tempo.validate_manifest_entries([self.entry, second])

    def test_expand_occupied_block_uses_next_original_start(self) -> None:
        """Use the next source start as the expanded range boundary."""
        first = tempo.WorklogEntry(
            issue="FL-217",
            start=datetime(2026, 6, 30, 9, 0, tzinfo=ZoneInfo("Europe/Berlin")),
            duration_minutes=15,
            description="First item",
            account=self.mapping,
        )
        second = tempo.WorklogEntry(
            issue="FL-218",
            start=datetime(
                2026, 6, 30, 10, 0, tzinfo=ZoneInfo("Europe/Berlin")
            ),
            duration_minutes=30,
            description="Second item",
            account=self.mapping,
        )

        expanded = tempo.expand_occupied_blocks([first, second])

        self.assertEqual(
            [
                (entry.start.strftime("%H:%M"), entry.duration_minutes)
                for entry in expanded
            ],
            [("08:30", 90), ("10:00", 30)],
        )

    def test_expand_single_item_fills_only_its_block(self) -> None:
        """Expand one suggestion without populating empty blocks."""
        expanded = tempo.expand_occupied_blocks([self.entry])

        self.assertEqual(len(expanded), 1)
        self.assertEqual(expanded[0].start.strftime("%H:%M"), "08:30")
        self.assertEqual(expanded[0].duration_minutes, 120)

    def test_expand_items_fills_each_occupied_block(self) -> None:
        """Fill each occupied block with 120 minutes."""
        afternoon = tempo.WorklogEntry(
            issue="FL-219",
            start=datetime(
                2026, 6, 30, 14, 45, tzinfo=ZoneInfo("Europe/Berlin")
            ),
            duration_minutes=15,
            description="Afternoon item",
            account=self.mapping,
        )

        expanded = tempo.expand_occupied_blocks([self.entry, afternoon])

        self.assertEqual(len(expanded), 2)
        self.assertEqual(sum(entry.duration_minutes for entry in expanded), 240)
        self.assertEqual(
            [entry.start.strftime("%H:%M") for entry in expanded],
            ["08:30", "13:30"],
        )

    def test_expand_splits_entry_across_block_boundary(self) -> None:
        """Fill both blocks when a suggestion crosses their boundary."""
        crossing = tempo.WorklogEntry(
            issue="FL-220",
            start=datetime(
                2026, 6, 30, 10, 15, tzinfo=ZoneInfo("Europe/Berlin")
            ),
            duration_minutes=30,
            description="Crossing item",
            account=self.mapping,
        )

        expanded = tempo.expand_occupied_blocks([crossing])

        self.assertEqual(
            [entry.start.strftime("%H:%M") for entry in expanded],
            ["08:30", "10:30"],
        )
        self.assertEqual(
            [entry.duration_minutes for entry in expanded], [120, 120]
        )

    def test_expand_rejects_entry_in_lunch_gap(self) -> None:
        """Reject a suggestion that occurs during the lunch gap."""
        lunch = tempo.WorklogEntry(
            issue="FL-221",
            start=datetime(
                2026, 6, 30, 12, 45, tzinfo=ZoneInfo("Europe/Berlin")
            ),
            duration_minutes=15,
            description="Lunch item",
            account=self.mapping,
        )

        with self.assertRaisesRegex(tempo.TempoClientError, "outside"):
            tempo.expand_occupied_blocks([lunch])

    def test_incorrect_existing_account_is_rejected(self) -> None:
        """Reject an existing Account value that conflicts with the mapping."""
        match = tempo.WorklogMatch(
            self.entry, jira_worklog_id=12, created=False
        )
        with self.assertRaisesRegex(
            tempo.TempoClientError, "Correct it manually"
        ):
            tempo.check_account_values([match], {12: 34}, {34: "WRONG"})


if __name__ == "__main__":
    unittest.main()
