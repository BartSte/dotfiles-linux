#!/usr/bin/env python3

import logging
import pickle
import random
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
    settings: Settings = Settings(**vars(args))
    mappings: Mappings = Mappings(path=settings.mappings)

    init_logger(settings.log, settings.loglevel)

    logging.info("Initializing logger")
    logging.info("Settings: %s", settings)

    make_directories(settings)
    logging.info("Logger initialized")

    mappings.load()

    domains: set[str] = download_blocklist(settings.url)
    domains_to_resolve: set[str] = find_domains_to_resolve(
        domains, mappings.domains, settings.part
    )
    logging.info("%s domains to resolve", len(domains_to_resolve))

    mappings.update({domain: [] for domain in domains_to_resolve})
    mappings.save()


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


class Mappings(dict[str, list[str]]):
    path: str

    def __init__(self, path: str):
        super().__init__()
        self.path = path

    @property
    def domains(self) -> set[str]:
        return set(self.keys())

    @property
    def ips(self) -> set[list[str]]:
        return set(self.values())

    def load(self):
        """Load a dictionary with that maps domains to IPs from a file.

        Here the `path` must contain a python pickled dictionary. If no file is
        found, an empty dictionary is returned.

        Args:
            path: Path to the file with the mappings.

        Returns:
            A dictionary with domains as keys and IPs as values.

        """
        try:
            with open(self.path, "rb") as f:
                self.update(pickle.load(f))
        except FileNotFoundError:
            logging.info("No mappings file found at %s", self.path)
        except pickle.UnpicklingError as e:
            raise InvalidCacheError(
                f"Invalid mappings file at {self.path}"
            ) from e
        except Exception as e:
            raise InvalidCacheError(
                f"Error loading mappings file at {self.path}"
            ) from e
        else:
            logging.info("Loaded %s mappings from %s", len(self), self.path)

    def save(self):
        """Save the mappings to `Mappings.path`."""
        makedirs(dirname(self.path), exist_ok=True)
        try:
            with open(self.path, "wb") as f:
                pickle.dump(self, f)
        except Exception as e:
            raise InvalidCacheError(
                f"Error saving mappings file at {self.path}"
            ) from e
        else:
            logging.info("Saved %s mappings to %s", len(self), self.path)


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
        part: Percentage of the subset of retained domains to resolve.

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
    n: int = len(domains) * part // 100
    return set(random.sample(list(domains), n))


class InvalidCacheError(Exception):
    """Raised when the cache file is invalid."""


if __name__ == "__main__":
    main()


################################################################################
# Tests
################################################################################
class TestParser(TestCase):
    parser: Parser
    _argv: list[str]

    def setUp(self):
        self.parser = Parser()
        self._argv = sys.argv

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
    mappings: Mappings

    def setUp(self) -> None:
        self.settings = Settings(mappings="/tmp/mappings")
        self.mappings = Mappings(path=self.settings.mappings)
        self.mappings.update(
            {
                "example.com": ["1.2.3.4"],
                "example.org": ["5.6.7.8", "9.10.11.12"],
            }
        )

    def tearDown(self) -> None:
        with suppress(FileNotFoundError):
            remove(self.settings.mappings)

    def test_valid(self):
        self.mappings.save()

        result = Mappings(self.settings.mappings)
        result.load()
        self.assertIsInstance(result, dict)
        self.assertEqual(result, self.mappings)

    def test_empty(self):
        result = Mappings("")
        result.load()

        self.assertIsInstance(result, dict)
        self.assertEqual(result, {})

    def test_invalid(self):
        with open(self.settings.mappings, "wb") as f:
            pickle.dump({"invalid", "object"}, f)

        result = Mappings(self.settings.mappings)
        with self.assertRaises(InvalidCacheError):
            result.load()


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
