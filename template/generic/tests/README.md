# Tests

The generic profile ships no test runner, because it does not know your toolchain.
It ships this directory and the contract the rest of the repository expects from it.

## The contract

`make test` calls `lang-test` in [`make/generic.mk`](../make/generic.mk), and CI calls
`make test`. Point `lang-test` at whatever runs the tests in this directory and everything
downstream — the CI workflow, `make verify`, the pre-commit hook — works unchanged. The same
holds for `lang-test-integration` and `lang-fuzz`.

Nothing else in the repository needs to know what the test framework is. That is the whole
point of the indirection: the profile is the only file that changes when the toolchain does.

## What belongs here

- **Smoke tests** — the minimum guarantee that the project is wired together: it builds, its
  entry point runs, it reports its version. Never let the suite reach zero.
- **Unit tests** — fast, no network, no privileges. These are what `make test` runs and what
  gates every pull request.
- **Integration tests** — anything that needs a real filesystem, a socket, or elevated rights.
  These go behind `lang-test-integration` so a contributor without that environment can still
  run `make test`.
- **Property-based tests** — for every function that parses or validates untrusted input. See
  [`DYNAMIC_ANALYSIS_POLICY.md`](../DYNAMIC_ANALYSIS_POLICY.md) for the triage process.

## Coverage

The OpenSSF silver criteria ask for 80% statement coverage, gold for 90% plus 80% branch
coverage. `make coverage` is the agreed entry point; wire it up in `make/generic.mk` once a
runner is in place.

<!-- TODO(template): replace this file with the real test suite once the toolchain is chosen. -->
