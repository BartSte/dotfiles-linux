#!/usr/bin/env python3

import asyncio
import logging
import pickle
import random
import socket
import sys
import textwrap
from argparse import ArgumentError, ArgumentParser, Namespace
from contextlib import suppress
from dataclasses import dataclass
from logging.handlers import RotatingFileHandler
from os import makedirs, remove
from os.path import dirname
from typing import Coroutine, Self, override
from unittest import TestCase

import aiodns
import requests

_DESCRIPTION = """
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
    sys.excepthook = excepthook
    parser = Parser()
    args: Namespace = parser.parse_args()
    settings: Settings = Settings(**vars(args))

    init_logger(settings.log, settings.loglevel)
    logging.info("Initializing logger")

    settings.makedirs()
    logging.info("Settings: %s", settings)

    mappings: Mappings = Mappings(path=settings.mappings)
    mappings.load()

    domains: Domains = Domains()
    domains.update_from_url(settings.url)

    diff: Domains = domains - mappings.domains
    retained: Domains = mappings.domains & domains
    resolve: Domains = retained.make_random_subset(settings.part) | diff
    logging.info("%s domains to resolve", len(resolve))

    mappings.update_by_resolving(resolve, settings.jobs)
    mappings.save()


def excepthook(type_: type[BaseException], value: BaseException, traceback):
    expected: tuple[type[BaseException], ...] = (
        KeyboardInterrupt,
        InvalidCacheError,
        ArgumentError,
    )
    if isinstance(value, expected):
        logging.error(value)
    else:
        logging.critical(
            "Unexpected error: ", exc_info=(type_, value, traceback)
        )
    sys.exit(1)


@dataclass
class Settings:
    debug: bool = False
    jobs: int = 0
    loglevel: str = "INFO"
    log: str = "/var/log/update-blocklist.log"
    ipset: str = "blocked-ips"
    part: int = 100
    mappings: str = "/var/cache/update-blocklist/mappings"
    url: str = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"

    def makedirs(self):
        """Create the directories from the settings.

        Args:
            settings: Settings object with the directories to create.

        """
        dirs: list[str] = [
            dirname(self.mappings),
        ]
        for d in dirs:
            logging.info("Trying to create directory %s", d)
            makedirs(d, exist_ok=True)


class Parser(ArgumentParser):
    def __init__(self):
        super().__init__(prog="update-blocklist", description=_DESCRIPTION)
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
            type=self.check_part,
            default=Settings.part,
            help=textwrap.dedent(
                """Percentage between 0 and 100 of the stored mappings to
                re-resolve."""
            ),
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

    def check_part(self, value: int | str) -> int:
        value = int(value)
        if not 0 <= value <= 100:
            raise ArgumentError(None, "part must be between 0 and 100")
        return value


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


class Domains(set[str]):
    def update_from_url(self, url: str) -> Self:
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
        self.update(
            line.split()[1]
            for line in response.text.splitlines()
            if line.startswith("0.0.0.0")
        )
        return self

    def make_random_subset(self, part: int) -> Self:
        """Return a random subset of the domains.

        The size of the subset is determined by the `part` percentage. If `part`
        is 100, the entire set is returned, if `part` is 0, an empty set is
        returned.

        Args:
            domains: Set of domains to get the subset from.
            part: Percentage of the subset to return.

        Returns:
            A random subset of the domains.

        """
        n: int = len(self) * part // 100
        cls: type[Self] = type(self)
        return cls(random.sample(list(self), n))

    @override
    def __sub__(self, other: Self) -> Self:
        return type(self)(super().__sub__(other))

    @override
    def __and__(self, other: Self) -> Self:
        return type(self)(super().__and__(other))

    @override
    def __or__(self, other: Self) -> Self:
        return type(self)(super().__or__(other))

    @override
    def __repr__(self) -> str:
        return f"{type(self).__name__}({super().__repr__()})"

    @override
    def __str__(self) -> str:
        return f"{type(self).__name__}({super().__str__()})"


class Mappings(dict[str, list[str]]):
    path: str
    _sem: asyncio.Semaphore
    _resolver: aiodns.DNSResolver

    def __init__(self, path: str):
        super().__init__()
        self.path = path

    @property
    def domains(self) -> Domains:
        return Domains(self.keys())

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
        logging.info("Saving %s mappings to %s", len(self), self.path)
        try:
            with open(self.path, "wb") as f:
                pickle.dump(dict(self), f)
        except Exception as e:
            raise InvalidCacheError(
                f"Error saving mappings file at {self.path}"
            ) from e

    def update_by_resolving(self, domains: Domains, jobs: int = 10000):
        logging.info("Asyncio event loop starting with %s workers", jobs)
        # TODO add a timeout to the resolver for requestst that take too long.
        asyncio.run(self._resolve_multiple(domains, jobs))
        logging.info("Asyncio event loop finished")

    async def _resolve_multiple(self, domains: Domains, jobs: int = 10000):
        self._sem = asyncio.Semaphore(jobs)
        self._resolver = aiodns.DNSResolver()
        tasks: list[Coroutine[None, None, tuple[str, list[str]]]] = [
            self._resolve(domain) for domain in domains
        ]
        logging.info("Resolving %s domains async", len(tasks))
        for i, future in enumerate(asyncio.as_completed(tasks)):
            domain, ips = await future
            self[domain] = ips
            if i % 1000 == 0:
                logging.info("Resolved %s domains", i)

    async def _resolve(self, domain: str) -> tuple[str, list[str]]:
        async with self._sem:
            try:
                # gethostbyname resolves the domain to IPv4 addresses.
                result = await self._resolver.gethostbyname(
                    domain, socket.AF_INET
                )
                ips: list[str] = result.addresses
                assert isinstance(ips, list)
                assert len(ips) == 0 or isinstance(ips[0], str)
                return domain, ips
            except Exception as e:
                return domain, []


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
        }
        sys.argv = ["update-blocklist"]
        sys.argv.extend([f"--{k}={v}" for k, v in argv.items()])

        args = self.parser.parse_args()
        settings = Settings(**vars(args))
        for key, value in argv.items():
            self.assertEqual(getattr(settings, key), value)


class TestDomains(TestCase):
    def test_valid(self):
        domains = Domains().update_from_url(Settings.url)
        self.assertIsInstance(domains, set)
        assert len(domains) > 10

    def test_invalid(self):
        with self.assertRaises(requests.exceptions.ConnectionError):
            Domains().update_from_url("https://notexisting_123abc.com")

    def test_not_domains_file(self):
        x = Domains().update_from_url("https://google.com")
        assert x == set()

    def test_operators(self):
        a = Domains({"a", "b", "c"})
        b = Domains({"b", "c", "d"})
        minus = a - b
        amp = a & b
        bar = a | b

        self.assertEqual(minus, {"a"})
        self.assertEqual(amp, {"b", "c"})
        self.assertEqual(bar, {"a", "b", "c", "d"})

        for x in [minus, amp, bar]:
            self.assertIsInstance(x, Domains)


class TestMappings(TestCase):
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

    def test_update_by_resolving(self):
        domains = Domains({"example.net", "example.nl"})
        self.mappings.update_by_resolving(domains)
        self.assertEqual(len(self.mappings), 4)
        print(self.mappings)


class TestGetSubset(TestCase):
    def test_empty(self):
        domains = Domains(set())
        subset = domains.make_random_subset(100)
        self.assertEqual(subset, set())

    def test_all(self):
        domains = Domains({"a", "b", "c"})
        subset = domains.make_random_subset(100)
        self.assertEqual(subset, domains)

    def test_half(self):
        domains = Domains({"a", "b", "c"})
        subset = domains.make_random_subset(67)
        self.assertTrue(subset.issubset(domains))
        self.assertTrue(len(subset) == 2, f"len: {len(subset)}")

    def test_large(self):
        domains = Domains({f"{x}" for x in range(100000)})
        subset = domains.make_random_subset(50)
        self.assertTrue(subset.issubset(domains))
        self.assertTrue(len(subset) == 50000, len(subset))
