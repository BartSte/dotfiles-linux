"""Regression tests for file and URL selection from tmux history."""

# Test method names describe each behavior.
# ruff: noqa: D102

import importlib.machinery
import importlib.util
import io
import json
import os
import shlex
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
LOADER = importlib.machinery.SourceFileLoader(
    "tmux_open_picker", str(ROOT / "bin/tmux-open-picker")
)
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
PICKER = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(PICKER)


class CandidateTests(unittest.TestCase):
    """Check path extraction without opening desktop applications."""

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        for name in (
            "notes.txt",
            "README",
            "photo.png",
            "space ' name.txt",
            "report:2026",
        ):
            (self.directory / name).write_text(
                "A document.\n", encoding="utf-8"
            )

    def find(self, content):
        return PICKER.find_candidates(content, self.directory)

    def test_files_urls_locations_and_recency(self):
        result = self.find(
            "notes.txt:12:3: compiler error\n"
            "photo.png\n"
            "https://example.invalid/a?q=1&b=2\n"
            "notes.txt:12:3: repeated error\n"
        )
        self.assertEqual(
            result,
            [
                str(self.directory / "notes.txt") + ":12:3",
                "https://example.invalid/a?q=1&b=2",
                str(self.directory / "photo.png"),
            ],
        )

    def test_preview_uses_latest_source_line_and_centers_highlight(self):
        locations = PICKER.find_candidate_lines(
            "notes.txt\nother text\nnotes.txt\n", self.directory
        )
        self.assertEqual(locations, {str(self.directory / "notes.txt"): 3})
        snapshot = self.directory / "preview.json"
        snapshot.write_text(
            json.dumps(
                {
                    "lines": [f"history {number}" for number in range(1, 61)],
                    "locations": [55],
                }
            ),
            encoding="utf-8",
        )
        output = io.StringIO()
        with (
            mock.patch.dict(os.environ, {"FZF_PREVIEW_LINES": "10"}),
            redirect_stdout(output),
        ):
            PICKER.show_preview(snapshot, 0)
        text = output.getvalue()
        plain_text = PICKER.ANSI_ESCAPE.sub("", text)
        self.assertTrue(plain_text.startswith("     50 history 50\n"))
        self.assertIn("\033[7m>    55 history 55\033[0m", text)
        self.assertIn("history 54\n", plain_text)
        self.assertIn("history 56\n", plain_text)
        with self.assertRaises(ValueError):
            PICKER.show_preview(snapshot, -1)

    def test_colors_do_not_change_paths_urls_or_traceback_locations(self):
        content = (
            "\033[31mnotes\033[0m.txt:\033[1m12:3\033[0m\n"
            "\033[38;2;100;150;200mhttps://example.invalid/a\033[0m?q=1\n"
            'File "\033[38;5;45mspace \' name.txt\033[0m", line 42\n'
            "\033]8;;https://example.invalid\033\\README\033]8;;\033\\\n"
        )
        self.assertEqual(
            self.find(content),
            [
                str(self.directory / "README"),
                str(self.directory / "space ' name.txt") + ":42",
                "https://example.invalid/a?q=1",
                str(self.directory / "notes.txt") + ":12:3",
            ],
        )

    def test_preview_preserves_colors_and_restores_selection_after_resets(self):
        snapshot = self.directory / "preview.json"
        lines = [
            "\033[32mgreen context\033[39m",
            "\033[31mred\033[0m selected\033[38;2;1;2;3m RGB\033[39m",
        ]
        snapshot.write_text(
            json.dumps({"lines": lines, "locations": [2]}), encoding="utf-8"
        )
        output = io.StringIO()
        with redirect_stdout(output):
            PICKER.show_preview(snapshot, 0)
        rendered = output.getvalue()
        self.assertIn(lines[0], rendered)
        self.assertIn("\033[31m\033[7mred\033[0m\033[7m selected", rendered)
        self.assertIn("\033[38;2;1;2;3m\033[7m RGB", rendered)
        self.assertTrue(rendered.endswith("\033[0m\n"))

    def test_traceback_and_quoted_paths(self):
        self.assertEqual(
            self.find('File "space \' name.txt", line 42, in main'),
            [str(self.directory / "space ' name.txt") + ":42"],
        )
        self.assertEqual(
            self.find('"space \' name.txt":12:8'),
            [str(self.directory / "space ' name.txt") + ":12:8"],
        )

    def test_absolute_relative_home_and_symlink(self):
        (self.directory / "link").symlink_to(self.directory / "notes.txt")
        self.assertEqual(
            self.find(str(self.directory / "notes.txt")),
            [str(self.directory / "notes.txt")],
        )
        self.assertEqual(
            self.find("./notes.txt"), [str(self.directory / "notes.txt")]
        )
        self.assertEqual(self.find("link"), [str(self.directory / "link")])
        with mock.patch.dict(os.environ, {"HOME": str(self.directory)}):
            self.assertEqual(
                self.find("~/notes.txt"), [str(self.directory / "notes.txt")]
            )

    def test_literal_colons_extensionless_files_and_punctuation(self):
        self.assertEqual(
            self.find("report:2026"), [str(self.directory / "report:2026")]
        )
        self.assertEqual(
            self.find("See README."), [str(self.directory / "README")]
        )
        self.assertEqual(
            self.find("(notes.txt:2:)"),
            [str(self.directory / "notes.txt") + ":2:1"],
        )
        self.assertEqual(
            self.find("https://example.invalid/a(b))."),
            ["https://example.invalid/a(b)"],
        )

    def test_missing_paths_and_directories_are_not_candidates(self):
        (self.directory / "folder").mkdir()
        self.assertEqual(
            self.find("missing.py:12 folder ordinary terminal output"), []
        )

    def test_windows_drive_and_unc_paths(self):
        with mock.patch.object(
            PICKER.subprocess,
            "check_output",
            side_effect=lambda args, **kwargs: (
                str(
                    self.directory
                    / ("notes.txt" if args[-1].endswith(".txt") else "missing")
                )
                + "\n"
            ),
        ) as convert:
            self.assertEqual(
                self.find(r"C:\Users\Bart\notes.txt:12:3"),
                [str(self.directory / "notes.txt") + ":12:3"],
            )
            self.assertTrue(
                any(
                    call.args[0]
                    == ["wslpath", "-ua", "C:/Users/Bart/notes.txt"]
                    for call in convert.call_args_list
                )
            )
            self.assertEqual(
                self.find(r'"\\server\share\space name.txt":2'),
                [str(self.directory / "notes.txt") + ":2"],
            )


class PickerTests(unittest.TestCase):
    """Check picker arguments, cancellation, and delegation to open."""

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.filename = self.directory / "photo ' name.png"
        self.filename.write_bytes(b"image")
        self.content = f'"{self.filename.name}"\n'
        self.cancel = False
        self.calls = []
        self.argv = mock.patch.object(
            PICKER.sys, "argv", ["tmux-open-picker", "%7"]
        )
        self.argv.start()
        self.addCleanup(self.argv.stop)

    def tmux_output(self, *arguments):
        if arguments[0] == "display-message":
            return str(self.directory) + "\n"
        self.assertEqual(
            arguments, ("capture-pane", "-eJp", "-t", "%7", "-S", "-5000")
        )
        return self.content

    def run_command(self, arguments, **kwargs):
        self.calls.append((arguments, kwargs))
        if arguments[0] == "fzf-tmux":
            self.assertIn("--read0", arguments)
            self.assertIn("--preview-window=right,60%,wrap", arguments)
            preview_command = shlex.split(
                arguments[arguments.index("--preview") + 1]
            )
            self.assertEqual(preview_command[-1], "{n}")
            self.preview_snapshot = Path(preview_command[-2])
            self.assertTrue(self.preview_snapshot.is_file())
            data = json.loads(self.preview_snapshot.read_text(encoding="utf-8"))
            self.assertEqual(data["lines"], self.content.splitlines())
            self.assertEqual(data["locations"], [1])
            self.assertEqual(
                kwargs["input"], os.fsencode(self.filename) + b"\0"
            )
            return subprocess.CompletedProcess(
                arguments,
                130 if self.cancel else 0,
                stdout=os.fsencode(self.filename) + b"\0",
            )
        return subprocess.CompletedProcess(arguments, 0)

    def run_picker(self):
        with (
            mock.patch.object(
                PICKER, "tmux_output", side_effect=self.tmux_output
            ),
            mock.patch.object(
                PICKER.subprocess, "run", side_effect=self.run_command
            ),
        ):
            return PICKER.main()

    def test_selection_uses_open_with_origin_context_and_literal_filename(self):
        self.assertEqual(self.run_picker(), 0)
        arguments, options = self.calls[-1]
        self.assertEqual(
            arguments,
            [str(ROOT / "bin/open"), "--linpath", "--", str(self.filename)],
        )
        self.assertEqual(options["cwd"], self.directory)
        self.assertEqual(options["env"]["TMUX_PANE"], "%7")

    def test_cancel_does_not_open_anything(self):
        self.cancel = True
        self.assertEqual(self.run_picker(), 0)
        self.assertEqual(len(self.calls), 1)
        self.assertFalse(self.preview_snapshot.exists())

    def test_colored_history_reaches_preview_but_selection_has_no_escape_codes(
        self,
    ):
        self.content = f'\033[31m"{self.filename.name}"\033[0m\n'
        self.assertEqual(self.run_picker(), 0)
        self.assertEqual(self.calls[-1][0][-1], str(self.filename))

    def test_no_candidates_displays_a_message(self):
        self.content = "No files here.\n"
        self.assertEqual(self.run_picker(), 0)
        self.assertEqual(
            self.calls[0][0],
            ["tmux", "display-message", "No files or URLs found."],
        )


if __name__ == "__main__":
    unittest.main()
