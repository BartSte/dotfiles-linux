#!/usr/bin/env python

import asyncio
import logging
import pickle
import random
import socket
import subprocess
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
from unittest.mock import MagicMock, patch

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
    """Main entry point for updating the blocklist.

    Downloads a blocklist from the specified URL, resolves the domains (or a
    subset of them), updates the stored domain→IP mappings, updates the ipset,
    and ensures the iptables rule is in place.
    """
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
    if settings.debug:
        domains.update({"example.com", "example.org"})
    else:
        domains.update_from_url(settings.url)

    diff: Domains = domains - mappings.domains
    retained: Domains = mappings.domains & domains
    resolve: Domains = retained.make_random_subset(settings.part) | diff
    logging.info("%s domains to resolve", len(resolve))

    mappings.update_by_resolving(resolve, settings.jobs, settings.timeout)

    mappings.save()

    ipset: IpSet = IpSet(settings.ipset)
    ipset.make()
    ipset.add(mappings.ips)
    ipset.block()


def excepthook(type_: type[BaseException], value: BaseException, traceback):
    """Global exception hook.

    Logs errors based on type and then exits.

    Args:
        type_ (type[BaseException]): The exception class.
        value (BaseException): The exception instance.
        traceback: Traceback object.

    """
    expected: tuple[type[BaseException], ...] = (
        KeyboardInterrupt,
        InvalidCacheError,
        ArgumentError,
        IpSetError,
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
    """Holds settings for the update-blocklist script.

    Attributes:
        debug (bool): Enable debug mode.
        ipset (str): Name of the ipset.
        jobs (int): Number of parallel jobs.
        log (str): Path to the log file.
        loglevel (str): Logging level.
        mappings (str): File path for domain→IP mappings.
        part (int): Percentage (0-100) of stored mappings to re-resolve.
        timeout (int): Timeout in seconds for resolving a domain.
        url (str): URL to download the blocklist from.

    """

    debug: bool = False
    ipset: str = "blocked"
    jobs: int = 10000
    log: str = "/var/log/update-blocklist.log"
    loglevel: str = "INFO"
    mappings: str = "/var/cache/update-blocklist/mappings"
    part: int = 100
    timeout: int = 5
    url: str = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"

    def makedirs(self):
        """Create the directories needed for the settings.

        Creates the parent directory for the mappings file.
        """
        dirs: list[str] = [dirname(self.mappings)]
        for d in dirs:
            logging.info("Trying to create directory %s", d)
            makedirs(d, exist_ok=True)


class Parser(ArgumentParser):
    """Custom argument parser for update-blocklist."""

    def __init__(self):
        """Initialize the parser with program arguments."""
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
                """\
                Percentage between 0 and 100 of the stored mappings to

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
        self.add_argument(
            "--timeout",
            type=int,
            help="Timeout for resolving a domain.",
            default=Settings.timeout,
        )

    def check_part(self, value: int | str) -> int:
        """Validate the part argument is between 0 and 100.

        Args:
            value (int | str): The input value for part.

        Returns:
            int: The validated integer value.

        Raises:
            ArgumentError: If the value is not between 0 and 100.

        """
        value = int(value)
        if not 0 <= value <= 100:
            raise ArgumentError(None, "part must be between 0 and 100")
        return value


def init_logger(logfile: str, level: str):
    """Initialize the root logger with a rotating file handler.

    Args:
        logfile (str): Path to the log file.
        level (str): Log level to set.

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
    """A set subclass for handling domains with additional operations."""

    def update_from_url(self, url: str) -> Self:
        """Download the blocklist from the URL and update the set with domains.

        Args:
            url (str): URL to download the blocklist from.

        Returns:
            Domains: The updated set of domains.

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
        """Return a random subset of the domains based on a percentage.

        Args:
            part (int): Percentage (0-100) of domains to include in the subset.

        Returns:
            Domains: A random subset of the domains.

        """
        n: int = len(self) * part // 100
        cls: type[Self] = type(self)
        return cls(random.sample(list(self), n))

    @override
    def __sub__(self, other: Self) -> Self:
        """Return the difference between two Domains sets."""
        return type(self)(super().__sub__(other))

    @override
    def __and__(self, other: Self) -> Self:
        """Return the intersection of two Domains sets."""
        return type(self)(super().__and__(other))

    @override
    def __or__(self, other: Self) -> Self:
        """Return the union of two Domains sets."""
        return type(self)(super().__or__(other))

    @override
    def __repr__(self) -> str:
        """Return the official string representation of the Domains set."""
        return f"{type(self).__name__}({super().__repr__()})"

    @override
    def __str__(self) -> str:
        """Return the informal string representation of the Domains set."""
        return f"{type(self).__name__}({super().__str__()})"


class Mappings(dict[str, list[str]]):
    """A dictionary mapping domains to a list of IPs with persistence and resolution.

    Attributes:
        path (str): Path to the pickled mappings file.

    """

    path: str
    _sem: asyncio.Semaphore
    _resolver: aiodns.DNSResolver

    def __init__(self, path: str):
        """Initialize the Mappings object.

        Args:
            path (str): File path to load/save the domain→IP mappings.

        """
        super().__init__()
        self.path = path

    @property
    def domains(self) -> Domains:
        """Return a Domains set containing all mapped domains.

        Returns:
            Domains: A set of domains.

        """
        return Domains(self.keys())

    @property
    def ips(self) -> set[str]:
        """Return a set of all IPs from the mappings.

        Returns:
            set[str]: A set of IP addresses.

        """
        return set(ip for ips in self.values() for ip in ips)

    def load(self):
        """Load domain→IP mappings from a pickle file.

        Raises:
            InvalidCacheError: If the mappings file is invalid.

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
        """Save the current domain→IP mappings to a pickle file.

        Raises:
            InvalidCacheError: If saving fails.

        """
        makedirs(dirname(self.path), exist_ok=True)
        logging.info("Saving %s mappings to %s", len(self), self.path)
        try:
            with open(self.path, "wb") as f:
                pickle.dump(dict(self), f)
        except Exception as e:
            raise InvalidCacheError(
                f"Error saving mappings file at {self.path}"
            ) from e

    def update_by_resolving(
        self, domains: Domains, jobs: int = 10000, timeout: int = 5
    ):
        """Update mappings by asynchronously resolving a set of domains.

        Args:
            domains (Domains): Set of domains to resolve.
            jobs (int, optional): Number of concurrent workers. Defaults to 10000.
            timeout (int, optional): Timeout in seconds for each resolution. Defaults to 5.

        """
        logging.info("Asyncio event loop starting with %s workers", jobs)
        asyncio.run(self._resolve_multiple(domains, jobs, timeout))
        logging.info("Asyncio event loop finished")

    async def _resolve_multiple(
        self, domains: Domains, jobs: int = 10000, timeout: int = 5
    ):
        """Resolve multiple domains concurrently.

        Args:
            domains (Domains): Set of domains to resolve.
            jobs (int, optional): Maximum number of concurrent resolutions.
            timeout (int, optional): Timeout for each resolution.

        """
        self._sem = asyncio.Semaphore(jobs)
        self._resolver = aiodns.DNSResolver()
        tasks: list[Coroutine[None, None, tuple[str, list[str]]]] = [
            self._resolve(domain, timeout) for domain in domains
        ]
        logging.info("Resolving %s domains async", len(tasks))
        for i, future in enumerate(asyncio.as_completed(tasks)):
            domain, ips = await future
            self[domain] = ips
            if i % 1000 == 0:
                logging.info("Resolved %s domains", i)
        logging.info("Resolved %s domains", len(tasks))

    async def _resolve(
        self, domain: str, timeout: int = 5
    ) -> tuple[str, list[str]]:
        """Asynchronously resolve a single domain to its IPv4 addresses.

        Args:
            domain (str): The domain to resolve.
            timeout (int, optional): Timeout for the resolution. Defaults to 5.

        Returns:
            tuple[str, list[str]]: A tuple containing the domain and a list of resolved IPs.

        """
        async with self._sem:
            try:
                result = await asyncio.wait_for(
                    self._resolver.gethostbyname(domain, socket.AF_INET),
                    timeout=timeout,
                )
                return domain, result.addresses
            except asyncio.TimeoutError:
                logging.debug("Timeout resolving %s", domain)
                return domain, []
            except aiodns.error.DNSError as e:
                logging.debug("Error resolving %s: %s", domain, e.args[1])
                return domain, []


class InvalidCacheError(Exception):
    """Raised when the mappings cache file is invalid."""


class IpSet:
    """A helper class for managing ipset operations.

    Attributes:
        name (str): The name of the ipset.

    """

    def __init__(self, name: str):
        """Initialize the IpSet.

        Args:
            name (str): The name of the ipset.

        """
        self.name = name

    def make(self):
        """Create the ipset.

        Raises:
            IpSetError: If creation fails.

        """
        try:
            exitcode: int = subprocess.check_call(
                ["ipset", "create", self.name, "hash:ip"],
                stderr=subprocess.DEVNULL,
            )
        except subprocess.CalledProcessError:
            exitcode = subprocess.check_call(["ipset", "flush", self.name])

        if not exitcode:
            logging.info("Empty ipset '%s' created", self.name)
        else:
            raise IpSetError(
                f"Error creating/flushing ipset {self.name}: the exit code was {exitcode}"
            )

    def add(self, ips: set[str]):
        """Add IPs to the ipset.

        Args:
            ips (set[str]): Set of IP addresses to add.

        Raises:
            IpSetError: If adding IPs fails.

        """
        commands: str = "\n".join(f"add {self.name} {ip}" for ip in ips)
        try:
            process = subprocess.run(
                ["ipset", "restore"], input=commands.encode(), check=True
            )
        except subprocess.CalledProcessError as e:
            raise IpSetError(
                f"Error adding IPs to ipset {self.name}: {e.stderr}"
            ) from e

        if not process.returncode:
            logging.info("Added %s IPs to ipset %s", len(ips), self.name)
        else:
            raise IpSetError(
                f"Error adding IPs to ipset {self.name}: the exit code was {process.returncode}"
            )

    def block(self):
        """Insert an iptables rule to block packets from IPs in the ipset.

        Raises:
            IpSetError: If blocking fails.

        """
        try:
            process = subprocess.run(
                [
                    "iptables",
                    "-I",
                    "INPUT",
                    "-m",
                    "set",
                    "--match-set",
                    self.name,
                    "src",
                    "-j",
                    "DROP",
                ],
                check=True,
            )
        except subprocess.CalledProcessError as e:
            raise IpSetError(
                f"Error blocking IPs in ipset {self.name}: {e.stderr}"
            ) from e

        if not process.returncode:
            logging.info("Blocked IPs in ipset %s", self.name)
        else:
            raise IpSetError(
                f"Error blocking IPs in ipset {self.name}: the exit code was {process.returncode}"
            )


class IpSetError(Exception):
    """Raised when an error occurs during ipset operations."""


if __name__ == "__main__":
    main()


################################################################################
# Tests
################################################################################


class TestParser(TestCase):
    """Test cases for the Parser class."""

    parser: Parser
    _argv: list[str]

    def setUp(self):
        """Set up test environment for Parser tests."""
        self.parser = Parser()
        self._argv = sys.argv.copy()

    def tearDown(self):
        """Restore sys.argv after tests."""
        sys.argv = self._argv

    def test_parse(self):
        """Test that the parser correctly parses given command-line arguments."""
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
    """Test cases for the Domains class."""

    def test_valid(self):
        """Test that update_from_url returns a set with domains."""
        domains = Domains().update_from_url(Settings.url)
        self.assertIsInstance(domains, set)
        self.assertTrue(len(domains) > 10)

    def test_invalid(self):
        """Test that update_from_url raises an error for an invalid URL."""
        with self.assertRaises(requests.exceptions.ConnectionError):
            Domains().update_from_url("https://notexisting_123abc.com")

    def test_not_domains_file(self):
        """Test that update_from_url returns an empty set when no valid domains are found."""
        x = Domains().update_from_url("https://google.com")
        self.assertEqual(x, set())

    def test_operators(self):
        """Test set operators on Domains."""
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
    """Test cases for the Mappings class."""

    settings: Settings
    mappings: Mappings

    def setUp(self) -> None:
        """Set up test environment for Mappings tests."""
        self.settings = Settings(mappings="/tmp/mappings")
        self.mappings = Mappings(path=self.settings.mappings)
        self.mappings.update(
            {
                "example.com": ["1.2.3.4"],
                "example.org": ["5.6.7.8", "9.10.11.12"],
            }
        )

    def tearDown(self) -> None:
        """Clean up after Mappings tests."""
        with suppress(FileNotFoundError):
            remove(self.settings.mappings)

    def test_valid(self):
        """Test saving and loading valid mappings."""
        self.mappings.save()
        result = Mappings(self.settings.mappings)
        result.load()
        self.assertIsInstance(result, dict)
        self.assertEqual(result, self.mappings)

    def test_empty(self):
        """Test loading when mappings file is empty or missing."""
        result = Mappings("/tmp/nonexistent_mappings")
        result.load()
        self.assertIsInstance(result, dict)
        self.assertEqual(result, {})

    def test_invalid(self):
        """Test that loading an invalid mappings file raises InvalidCacheError."""
        with open(self.settings.mappings, "wb") as f:
            pickle.dump({"invalid", "object"}, f)
        result = Mappings(self.settings.mappings)
        with self.assertRaises(InvalidCacheError):
            result.load()

    def test_update_by_resolving(self):
        """Test that update_by_resolving correctly adds new mappings."""
        domains = Domains({"example.net", "example.nl"})
        self.mappings.update_by_resolving(domains)
        # Expect at least 4 mappings: the two originally set plus two new ones.
        self.assertGreaterEqual(len(self.mappings), 4)
        print(self.mappings)


class TestGetSubset(TestCase):
    """Test cases for the make_random_subset method in Domains."""

    def test_empty(self):
        """Test that an empty Domains set returns an empty subset."""
        domains = Domains(set())
        subset = domains.make_random_subset(100)
        self.assertEqual(subset, set())

    def test_all(self):
        """Test that 100% subset returns the entire set."""
        domains = Domains({"a", "b", "c"})
        subset = domains.make_random_subset(100)
        self.assertEqual(subset, domains)

    def test_half(self):
        """Test that a 67% subset of three items returns two items."""
        domains = Domains({"a", "b", "c"})
        subset = domains.make_random_subset(67)
        self.assertTrue(subset.issubset(domains))
        self.assertEqual(len(subset), 2, f"len: {len(subset)}")

    def test_large(self):
        """Test that a 50% subset of 100,000 items returns exactly 50,000 items."""
        domains = Domains({f"{x}" for x in range(100000)})
        subset = domains.make_random_subset(50)
        self.assertTrue(subset.issubset(domains))
        self.assertEqual(len(subset), 50000)


class TestSettings(TestCase):
    """Test cases for the Settings class."""

    def test_makedirs(self):
        """Test that makedirs creates the required directory for mappings."""
        import os
        from tempfile import TemporaryDirectory

        with TemporaryDirectory() as tmpdirname:
            settings = Settings(mappings=f"{tmpdirname}/subdir/mappings_file")
            settings.makedirs()
            self.assertTrue(os.path.isdir(dirname(settings.mappings)))


class TestIpSet(TestCase):
    def setUp(self):
        """Set up a test IpSet instance."""
        self.ipset_name = "test_ipset"
        self.ipset = IpSet(self.ipset_name)

    @patch("subprocess.check_call")
    def test_make_success(self, mock_check_call):
        """Test that IpSet.make() succeeds when subprocess calls succeed."""
        mock_check_call.return_value = 0
        self.ipset.make()
        self.assertTrue(mock_check_call.called)

    @patch("subprocess.run")
    def test_add_success(self, mock_run):
        """Test that IpSet.add() succeeds when subprocess.run returns returncode 0."""
        fake_process = MagicMock()
        fake_process.returncode = 0
        mock_run.return_value = fake_process
        ips = {"1.2.3.4", "5.6.7.8"}
        self.ipset.add(ips)
        self.assertTrue(mock_run.called)

    @patch("subprocess.run")
    def test_add_failure(self, mock_run):
        """Test that IpSet.add() raises an IpSetError when adding IPs fails."""
        mock_run.side_effect = subprocess.CalledProcessError(
            1, ["ipset", "restore"]
        )
        with self.assertRaises(IpSetError):
            self.ipset.add({"1.2.3.4"})

    @patch("subprocess.run")
    def test_block_success(self, mock_run):
        """Test that IpSet.block() succeeds when iptables command returns returncode 0."""
        fake_process = MagicMock()
        fake_process.returncode = 0

        mock_run.return_value = fake_process
        self.ipset.block()
        self.assertTrue(mock_run.called)

    @patch("subprocess.run")
    def test_block_failure(self, mock_run):
        """Test that IpSet.block() raises an IpSetError when blocking fails."""
        mock_run.side_effect = subprocess.CalledProcessError(
            1,
            [
                "iptables",
                "-I",
                "INPUT",
                "-m",
                "set",
                "--match-set",
                self.ipset_name,
                "src",
                "-j",
                "DROP",
            ],
        )
        with self.assertRaises(IpSetError):
            self.ipset.block()
