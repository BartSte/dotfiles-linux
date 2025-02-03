#!/usr/bin/env python3

import sys
from argparse import ArgumentParser
from dataclasses import dataclass
from os import makedirs
from os.path import dirname
from typing import Generator
from unittest import TestCase

import requests

_USAGE = """
Download the URL blocklist into the BLOCKLIST file. Resolve the IPs of the
domains in the blocklist and add them to an ipset named IPSET_NAME. Then add an
iptables rule to drop packets to those IPs.

To avoid rate limiting, the blocklist is resolved in parallel with a number of
jobs (-j). The blocklist may be processed in parts (-p), meaning only that
percentage of *existing mappings* will be re-resolved each run.

By storing domain→IP mappings in a file (-m), we can skip re-resolving domains
unnecessarily:

- New domains (in blocklist but not in mappings) are always resolved.
- Domains no longer in the blocklist are removed from ipset.
- A random N% of *existing* domains are re-resolved on each run.
"""


@dataclass
class Settings:
    debug: bool = False
    jobs: int = 0
    loglevel: str = "INFO"
    ipset: str = "blocked-ips"
    part: int = 100
    domains: str = "/etc/blocked-domains.txt"
    mappings: str = "/var/cache/blocked-domains-with-ips.txt"
    url: str = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"


class Parser(ArgumentParser):
    def __init__(self):
        super().__init__(prog="update-blocklist", usage=_USAGE)
        self.add_argument(
            "-u",
            "--url",
            default=Settings.url,
            help="URL to download the domains from.",
        )
        self.add_argument(
            "-j",
            "--jobs",
            type=int,
            help="Number of jobs to run in parallel.",
            default=Settings.jobs,
        )
        self.add_argument(
            "-l",
            "--loglevel",
            choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
            help="Set the log level.",
            default=Settings.loglevel,
        )
        self.add_argument(
            "-m",
            "--mappings",
            help="Path to the file with domain→IP mappings.",
            default=Settings.mappings,
        )
        self.add_argument(
            "-i",
            "--ipset",
            help="Name of the ipset to add the IPs to.",
            default=Settings.ipset,
        )
        self.add_argument(
            "-p",
            "--part",
            type=int,
            help="Percentage of existing mappings to resolve.",
            default=Settings.part,
        )
        self.add_argument(
            "-d",
            "--domains",
            help="Path to the file with the domains.",
            default=Settings.domains,
        )
        self.add_argument(
            "--debug",
            action="store_true",
            help="Enable debug mode.",
            default=Settings.debug,
        )


def main():
    parser = Parser()
    args = parser.parse_args()
    settings = Settings(**vars(args))

    makedirs(dirname(settings.mappings), exist_ok=True)
    makedirs(dirname(settings.domains), exist_ok=True)

    download_blocklist(settings.url, settings.domains)

    print(settings)


def download_blocklist(url: str, output: str) -> set[str]:
    """Download the blocklist from the URL and parse it into a file.

    The blocklist is a list of domains that should be blocked. The file is
    parsed to extract the domains and write them to the output file.

    Args:
        url: URL to download the blocklist from.
        output: Path to the file to write the domains to.

    Returns:
        A set with the domains in the blocklist.

    """
    response: requests.Response = requests.get(url)
    response.raise_for_status()
    with open(output, "w") as f:
        lines: set[str] = {
            line.split()[1]
            for line in response.text.splitlines()
            if line.startswith("0.0.0.0")
        }
        for line in set(lines):
            f.write(line.split()[1] + "\n")

    return lines


if __name__ == "__main__":
    main()


################################################################################
# Tests
################################################################################
class TestParser(TestCase):
    parser: Parser

    def setUp(self):
        self.parser = Parser()
        self._argv: list[str] = sys.argv

    def tearDown(self):
        sys.argv = self._argv

    def test_parse(self):
        argv: dict[str, str | int] = {
            "url": "https://example.com",
            "jobs": 10,
            "loglevel": "INFO",
            "mappings": "/tmp/mappings.txt",
            "ipset": "blocked-ips",
            "part": 50,
            "domains": "/tmp/domains.txt",
        }
        sys.argv = ["update-blocklist"]
        sys.argv.extend([f"--{k}={v}" for k, v in argv.items()])

        args = self.parser.parse_args()
        settings = Settings(**vars(args))
        for key, value in argv.items():
            self.assertEqual(getattr(settings, key), value)
