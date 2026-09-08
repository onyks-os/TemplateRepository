"""Smoke tests — the minimum guarantee that the package is importable and wired up.

Delete these once real tests exist, but never let the suite reach zero tests:
a green pipeline with no assertions is worse than a red one.
"""

from __future__ import annotations

import pytest

import {{PROJECT_PKG}}
from {{PROJECT_PKG}}.cli import EXIT_OK, build_parser, main


def test_version_is_exposed() -> None:
    assert {{PROJECT_PKG}}.__version__


def test_parser_builds() -> None:
    assert build_parser().prog == "{{PROJECT_PKG}}"


def test_main_returns_success() -> None:
    assert main([]) == EXIT_OK


def test_version_flag_exits_zero(capsys: pytest.CaptureFixture[str]) -> None:
    with pytest.raises(SystemExit) as excinfo:
        main(["--version"])
    assert excinfo.value.code == 0
    assert {{PROJECT_PKG}}.__version__ in capsys.readouterr().out
