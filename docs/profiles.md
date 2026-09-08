# Language Profiles

A profile is the only part of the template that knows what language a project is written in.
Everything else — governance, security policy, documentation, release pipeline, and the meaning of
`make verify` — is shared.

## The `lang-*` contract

`make/quality.mk`, `make/common.mk`, and `make/release.mk` orchestrate; the profile implements. A
profile must define all nine targets, even if some are no-ops:

| Target | Must do | Called by |
| :----- | :------ | :-------- |
| `lang-setup` | Create the environment, install dev dependencies | `make setup` |
| `lang-lint` | Lint, format-check, and type-check first-party source | `make lint` |
| `lang-format` | Auto-format and auto-fix | `make format` |
| `lang-test` | Fast unit tests, no privileges required | `make test` |
| `lang-test-integration` | Integration tests | `make integration-test` |
| `lang-fuzz` | Property-based / fuzz tests | `make fuzz` |
| `lang-audit` | Dependency vulnerability scan | `make audit` |
| `lang-build` | Produce artifacts into `$(DIST_DIR)` | `make build` |
| `lang-clean` | Remove language-specific caches and artifacts | `make clean` |

`make check-profiles` verifies this contract for every profile in the repository, so a profile
cannot silently drift out of compliance.

Variables available to a profile fragment, set by the generated `Makefile`: `PROJECT_NAME`,
`PROJECT_SHORT`, `PROJECT_SLUG`, `PROJECT_PKG`, `PROJECT_DIST`, `GITHUB_OWNER`, `VERSION`,
`SRC_DIRS`, `TEST_DIRS`, `SCRIPT_DIRS`, and `DIST_DIR`.

## What ships in each profile

### `python`

- `pyproject.toml` with hatchling, Ruff (including `flake8-bandit` security rules), mypy, coverage,
  pytest markers, and `bump-my-version` wired to every file that carries the version string.
- Package skeleton with a thin CLI orchestrator, a smoke test suite, and Hypothesis fuzz targets.
- `fuzzing/conftest.py` registering `dev` / `ci` / `ci-deep` Hypothesis profiles, so pull requests
  stay fast while the weekly scheduled run explores 10,000 examples.
- CI: Ruff, mypy, ShellCheck, a 3.10–3.13 test matrix, `pip-audit`, and a wheel smoke-install in a
  clean virtualenv — which catches packaging mistakes that an editable install hides.

### `node`

- Strict `tsconfig.json` with every soundness flag enabled, plus a separate build config so tests
  are type-checked but not shipped.
- Flat ESLint config using type-aware `strictTypeChecked` rules, with type-aware linting disabled
  for plain-JS config files.
- Prettier scoped to source: Markdown is governed by `.markdownlint.yaml`, and workflows are left
  alone.
- Vitest with coverage; CI runs a Node 20/22 matrix and `npm audit`.

### `rust`

- `Cargo.toml` with `unsafe_code = "forbid"`, `missing_docs`, Clippy `pedantic`, and warnings on
  `unwrap`/`expect`/`panic` in the crate lint table, plus `overflow-checks = true` in the release
  profile — an integer overflow in production is a correctness bug, not a performance question.
- Library plus binary layout, with proptest property tests.
- CI runs fmt, Clippy with `-D warnings`, a stable/beta/MSRV matrix, and `rustsec/audit-check`.

### `generic`

Every `lang-*` target is a documented no-op that announces itself. Use it for polyglot repositories
or as the starting point for a new profile.

## Adding a profile

```bash
cp -r template/generic template/go
```

1. Edit `template/go/profile.env` — language name, Shields logo slug, minimum version, CodeQL
   language id, Dependabot ecosystem, linter name, and `SKELETON_PATHS` (the source and test
   directories that form the runnable example, skipped as a unit when the target already has its
   own source there).
2. Rename `make/generic.mk` to `make/go.mk` and implement the nine targets.
3. Replace `.github/workflows/ci.yml` with a real pipeline, and add the toolchain setup step to
   `release.yml`.
4. Write `.gitignore.append` for the language's build output.
5. Add a minimal source skeleton and a smoke test — a profile whose `make test` finds no tests is a
   profile that ships a green pipeline proving nothing.
6. Run `make check-profiles`, then generate a scratch project and actually run
   `make lint test build` inside it.

Step 6 is not optional. Every profile in this repository was found to have at least one real bug
that only surfaced by running the generated project: a fuzz suite that collected zero tests, a Rust
crate name that did not match its package name, a TypeScript `rootDir` that excluded the tests it
was asked to check.
