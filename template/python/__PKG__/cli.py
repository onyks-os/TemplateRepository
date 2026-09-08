"""Command line entry point for {{PROJECT_SHORT}}.

This layer is a thin orchestrator: it parses arguments, calls into the core, and
formats the result. Keep business logic out of it so the core stays testable
without a terminal — see the architectural principles in CONTRIBUTING.md.
"""

from __future__ import annotations

import argparse
import sys
from collections.abc import Sequence

from . import __version__

EXIT_OK = 0
EXIT_ERROR = 1
EXIT_USAGE = 2


def build_parser() -> argparse.ArgumentParser:
    """Construct the argument parser.

    Kept separate from :func:`main` so tests can assert on the parser without
    executing anything.
    """
    parser = argparse.ArgumentParser(
        prog="{{PROJECT_PKG}}",
        description="{{PROJECT_DESC}}",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    # TODO(template): declare the real commands, then mirror them in docs/interfaces.md.
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Run the CLI and return a process exit code."""
    parser = build_parser()
    parser.parse_args(argv)

    # TODO(template): dispatch to the core here.
    print("{{PROJECT_SHORT}} v" + __version__)
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
