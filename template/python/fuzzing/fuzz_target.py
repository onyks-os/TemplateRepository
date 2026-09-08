"""Property-based fuzzing targets.

Every function that parses or validates untrusted input belongs here. The
contract these tests enforce is: for any input, the function either returns a
valid result or raises a documented exception — it never crashes with an
unexpected error type and never hangs.

See DYNAMIC_ANALYSIS_POLICY.md for the triage and remediation process.
"""

from __future__ import annotations

from hypothesis import given
from hypothesis import strategies as st

from {{PROJECT_PKG}}.cli import build_parser


@given(st.text())
def test_parser_never_crashes_on_arbitrary_input(argument: str) -> None:
    """Argument parsing rejects bad input cleanly, never with an unexpected error."""
    parser = build_parser()
    try:
        parser.parse_args([argument])
    except SystemExit:
        # argparse exits with code 2 on invalid usage; that is the documented contract.
        pass


# TODO(template): add one target per parser, deserializer, and regex reachable
# from untrusted input, and list them in DYNAMIC_ANALYSIS_POLICY.md.
