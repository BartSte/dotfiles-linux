#!/usr/bin/env python3
import logging
import pickle
import sys
from argparse import ArgumentParser, Namespace
from contextlib import suppress
from dataclasses import dataclass
from os import makedirs, remove
from os.path import dirname
from typing import Generator, override
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


def main():
    parser = Parser()
    args: Namespace = parser.parse_args()
    settings = Settings(**vars(args))
    make_directories(settings)
    domains: set[str] = download_blocklist(settings.url)
    mappings: dict[str, str | list[str]] = load_mappings(settings.mappings)

    print(domains)


@dataclass
class Settings:
    debug: bool = False
    jobs: int = 0
    loglevel: str = "INFO"
    logs: str = "/var/log/update-blocklist.log"
    ipset: str = "blocked-ips"
    part: int = 100
    domains: str = "/var/cache/update-blocklist/domains"
    mappings: str = "/var/cache/update-blocklist/mappings"
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
            "--logs", help="Path to the logs.", default=Settings.logs
        )
        self.add_argument(
            "--debug",
            action="store_true",
            help="Enable debug mode.",
            default=Settings.debug,
        )


def make_directories(settings: Settings):
    """Create the directories from the settings.

    Args:
        settings: Settings object with the directories to create.

    """
    dirs: list[str] = [
        settings.logs,
        dirname(settings.domains),
        dirname(settings.mappings),
    ]
    for d in dirs:
        makedirs(d, exist_ok=True)


def download_blocklist(url: str) -> set[str]:
    """Download the blocklist from the URL and parse it into a file.

    The blocklist is a list of domains that should be blocked. The file is
    parsed to extract the domains and write them to the output file.

    Args:
        url: URL to download the blocklist from.

    Returns:
        A set with the domains in the blocklist.

    """
    response: requests.Response = requests.get(url)
    response.raise_for_status()
    return {
        line.split()[1]
        for line in response.text.splitlines()
        if line.startswith("0.0.0.0")
    }


def load_mappings(path: str) -> dict[str, str | list[str]]:
    """Load a dictionary with that maps domains to IPs from a file.

    Here the `path` must contain a python pickled dictionary. If no file is
    found, an empty dictionary is returned.

    Args:
        path: Path to the file with the mappings.

    Returns:
        A dictionary with domains as keys and IPs as values.

    """
    try:
        with open(path, "rb") as f:
            result = pickle.load(f)
    except FileNotFoundError:
        logging.info("No mappings file found at %s", path)
        return {}
    except pickle.UnpicklingError as e:
        raise InvalidCacheError(f"Invalid mappings file at {path}") from e
    else:
        if not isinstance(result, dict):
            raise InvalidCacheError("The mappings file at %s is not a dict")
        return result


class InvalidCacheError(Exception):
    """Raised when the cache file is invalid."""


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


class TestDownloadBlocklist(TestCase):
    def test_valid(self):
        domains = download_blocklist(Settings.url)
        self.assertIsInstance(domains, set)
        assert len(domains) > 10

    def test_invalid(self):
        with self.assertRaises(requests.exceptions.ConnectionError):
            download_blocklist("https://notexisting_123abc.com")

    def test_not_domains_file(self):
        x = download_blocklist("https://google.com")
        assert x == set()


class TestLoadMappings(TestCase):
    settings: Settings
    mappings: dict[str, str | list[str]]

    def setUp(self) -> None:
        self.settings = Settings(mappings="/tmp/mappings")
        self.mappings = {
            "example.com": "1.2.3.4",
            "example.org": ["5.6.7.8", "9.10.11.12"],
        }

    def tearDown(self) -> None:
        with suppress(FileNotFoundError):
            remove(self.settings.mappings)

    def test_valid(self):
        with open(self.settings.mappings, "wb") as f:
            pickle.dump(self.mappings, f)

        result = load_mappings(self.settings.mappings)
        self.assertIsInstance(result, dict)
        self.assertEqual(result, self.mappings)

    def test_empty(self):
        result = load_mappings(self.settings.mappings)
        self.assertIsInstance(result, dict)
        self.assertEqual(result, {})

    def test_invalid(self):
        with open(self.settings.mappings, "wb") as f:
            pickle.dump({"invalid", "object"}, f)

        with self.assertRaises(InvalidCacheError):
            load_mappings(self.settings.mappings)
