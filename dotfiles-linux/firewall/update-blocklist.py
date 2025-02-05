#!/usr/bin/env python3

import logging
import pickle
import sys
from argparse import ArgumentParser, Namespace
from contextlib import suppress
from dataclasses import dataclass
from logging.handlers import RotatingFileHandler
from os import makedirs, remove
from os.path import dirname
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

    init_logger(settings.log, settings.loglevel)

    logging.info("Initializing logger")
    logging.info("Settings: %s", settings)

    make_directories(settings)
    logging.info("Logger initialized")

    mappings: dict[str, list[str]] = load_mappings(settings.mappings)
    domains: set[str] = download_blocklist(settings.url)
    domains_cache: set[str] = set(mappings.keys())
    domains_to_resolve: set[str] = find_domains_to_resolve(
        domains, domains_cache, settings.part
    )

    # print(domains_to_resolve)


@dataclass
class Settings:
    debug: bool = False
    jobs: int = 0
    loglevel: str = "INFO"
    log: str = "/var/log/update-blocklist"
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
            "--log", help="Path to the log file.", default=Settings.log
        )
        self.add_argument(
            "--debug",
            action="store_true",
            help="Enable debug mode.",
            default=Settings.debug,
        )


def init_logger(logfile: str, level: str):
    """Initialize the root logger with a rotating file handler.

    Args:
        logfile: Path to the log file.
        level: Log level to set.

    """
    logger = logging.getLogger()
    level = getattr(logging, level)
    file = RotatingFileHandler(logfile, maxBytes=1 * 1024 * 1024, backupCount=5)
    stream = logging.StreamHandler()
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    file.setLevel(level)
    file.setFormatter(formatter)

    stream.setLevel(level)
    stream.setFormatter(formatter)

    logger.setLevel(level)
    logger.addHandler(file)
    logger.addHandler(stream)


def make_directories(settings: Settings):
    """Create the directories from the settings.

    Args:
        settings: Settings object with the directories to create.

    """
    dirs: list[str] = [
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


def load_mappings(path: str) -> dict[str, list[str]]:
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


def find_domains_to_resolve(
    new: set[str], old: set[str] | None = None, part: int = 100
) -> set[str]:
    """Find the domains that need to be resolved.

    These are:
        - The domains that are new, i.e., not in `old`.
        - A random subset of the domains that are retained, i.e., they are both
          in `new` and `old`.

    Args:
        new: Set of domains to resolve.
        old: Set of domains resolved in the previous run.

    Returns:
        Set of domains to resolve.

    """
    if old is None:
        return new

    diff: set[str] = new - old
    retained: set[str] = old & new
    retained_subset: set[str] = get_subset(retained, part)
    return retained_subset | diff


def get_subset(domains: set[str], part: int) -> set[str]:
    """Return a random subset of the domains.

    The size of the subset is determined by the `part` percentage. If `part` is
    100, the entire set is returned, if `part` is 0, an empty set is returned.

    Args:
        domains: Set of domains to get the subset from.
        part: Percentage of the subset to return.

    Returns:
        A random subset of the domains.

    """
    # TODO: for now, just return the entire set or not
    if part:
        return domains
    else:
        return set()


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
    mappings: dict[str, list[str]]

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


class TestFindDomainsToResolve(TestCase):
    def test_only_new(self):
        new = {"a", "b", "c"}
        old = None
        result = find_domains_to_resolve(new, old, 0)
        self.assertEqual(result, new)

    def test_only_retained(self):
        new = set()
        old = {"a", "b", "c"}
        result = find_domains_to_resolve(new, old, 0)
        self.assertEqual(result, set())

    def test_new_and_retained(self):
        new = {"a", "b", "c"}
        old = {"b", "c", "d"}
        result = find_domains_to_resolve(new, old, 0)
        self.assertEqual(result, {"a"})
