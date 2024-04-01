#!/usr/bin/env python3

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


def make_parser() -> ArgumentParser:
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
        default=tmux("display-message", "-p", "#S"),
        help="Specify the tmux session, default to current session",
    )
    parser.add_argument(
        "-w",
        "--window",
        default=environ.get(
            "KEY2PANE_WINDOW", tmux("display-message", "-p", "#I")
        ),
        help="Specify the tmux window. If not provided, the KEY2PANE_WINDOW "
        "environment variable will be used, if not set, the current window will"
        " be used.",
    )
    parser.add_argument(
        "-p",
        "--pane",
        default=environ.get(
            "KEY2PANE_PANE", tmux("display-message", "-p", "#P")
        ),
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


def tmux(*args) -> str:
    return subprocess.check_output(["tmux", *args]).decode("utf-8").strip()


def main():
    parser: ArgumentParser = make_parser()
    args: Namespace = parser.parse_args()


if __name__ == "__main__":
    main()
