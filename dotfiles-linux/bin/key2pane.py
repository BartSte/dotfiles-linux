#!/usr/bin/env python3

import logging
from os import environ
import subprocess
from os.path import expanduser
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter

_DESCRIPTION: str = """
Sends a sequence of keys to any tmux pane, based on the pane's current command.

Which keys to send, must be specified in a json with the following format:

{
    "bash|zsh|fish": ["echo hello_world", "Enter"],
}

here, the key is the regex that will be matched against the current pane's
command. The value is an array of arguments that will be applied to the `tmux
send-keys` command. In the example above, if the current pane is running bash,
zsh, or fish, then the command `echo hello_world` will be sent to the pane.
Finally the command `Enter` will be sent to the pane, which has a special effect
for the `tmux send-keys` command, as it will simulate pressing the Enter key,
instead of literally typing the word Enter.

The positional arguments passed to this script can be used to populate
placeholders in the json values. The placeholders are curly braces with an
optional number inside, where the number indicates which argument to use,
starting from 1. So {1} will be replaced by the first argument, {2} by the
second, and so on. If no number is provided, all the arguments will be used. For
example, if the command is: `key2pane foo bar`, and the json value is: `echo {1}
{2}`, then the following keys will be sent to the pane: `echo foo bar`.

The curly braces can be escaped by using a backslash. For example, {1} will be
replaced by {1}, and not by the first argument.
"""


class Tmux:
    def __init__(self, sep: str = ":"):
        self._sep: str = sep
        self._session: str
        self._window: int
        self._pane: int
        self._command: str

        self.update()

    def update(self):
        self._update_active_interface(self._sep)
        self._update_command(*self.active_interface)

    def _update_active_interface(self, sep: str = ":"):
        active: str = self._cmd(("display-message", "-p", f"#S{sep}#I{sep}#P"))
        self._session, window, pane = active.split(sep)
        self._window = int(window)
        self._pane = int(pane)
        logging.debug("Active session:window:pane is: %s", active)

    def _update_command(self, session: str, window: int, pane: int):
        stdout_lines: list[str] = self._cmd(
            (
                "list-panes",
                "-t",
                f"{session}:{window}",
                "-F",
                "#{pane_index}:#{pane_current_command}",
            )
        ).splitlines()
        logging.debug(
            "Commands for %s:%s per pane: %s",
            session,
            window,
            stdout_lines,
        )
        index_vs_commands: tuple[tuple[int, str], ...] = tuple(
            (
                int(index),
                command,
            )
            for index, command in (line.split(":") for line in stdout_lines)
        )
        for index, command in index_vs_commands:
            if int(index) == pane:
                self._command = command
                logging.debug("Current command: %s", self.command)
                break
        else:
            logging.error("Current pane not found in %s", index_vs_commands)

    def _cmd(self, args: tuple[str, ...]) -> str:
        return subprocess.check_output(["tmux", *args]).decode("utf-8").strip()

    @property
    def active_interface(self) -> tuple[str, int, int]:
        return self._session, self._window, self._pane

    @property
    def session(self) -> str:
        return self._session

    @property
    def window(self) -> int:
        return self._window

    @property
    def pane(self) -> int:
        return self._pane

    @property
    def command(self) -> str:
        return self._command


def make_parser(session: str, window: int, pane: int) -> ArgumentParser:
    parser: ArgumentParser = ArgumentParser(
        description=_DESCRIPTION, formatter_class=RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "-c",
        "--config",
        default=expanduser("~/.config/key2pane/config.json"),
        help="The path to the config file. The default is "
        "~/.config/key2pane/config.json",
    )
    parser.add_argument(
        "-s",
        "--session",
        default=session,
        help="Specify the tmux session, default to current session",
    )
    parser.add_argument(
        "-w",
        "--window",
        default=environ.get("KEY2PANE_WINDOW", window),
        help="Specify the tmux window. If not provided, the KEY2PANE_WINDOW "
        "environment variable will be used, if not set, the current window will"
        " be used.",
    )
    parser.add_argument(
        "-p",
        "--pane",
        default=environ.get("KEY2PANE_PANE", pane),
        help="Specify the tmux pane. If not provided, the KEY2PANE_PANE "
        "environment variable will be used, if not set, the current pane will be"
        " used.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        default=False,
        help="Also log messages to stdout",
        action="store_true",
    )
    parser.add_argument(
        "--logfile",
        default=expanduser("~/.local/state/key2pane.log"),
        help="Specify the log file",
    )

    return parser


def main():
    logging.basicConfig(level=logging.DEBUG)
    tmux: Tmux = Tmux()
    parser: ArgumentParser = make_parser(tmux.session, tmux.window, tmux.pane)
    args: Namespace = parser.parse_args()


if __name__ == "__main__":
    main()
