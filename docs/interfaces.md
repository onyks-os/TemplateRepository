# Interfaces

Every command-line flag, Make target, and file contract this repository exposes. This is the
reference; [`usage.md`](usage.md) is the narrative walkthrough.

## `make` — the entry point

| Target | What it does |
| :--- | :--- |
| `make help` | List every target with its description. The default goal. |
| `make new TARGET=<dir> [PROFILE=<name>]` | Scaffold a repository. Never overwrites. |
| `make dry-run TARGET=<dir> [PROFILE=<name>]` | Print what `new` would write, change nothing. |
| `make audit [REPO=<dir>] [LEVEL=<level>]` | OpenSSF readiness report. Defaults to this repository. |
| `make test` | The end-to-end suite: scaffold every profile, audit the output. |
| `make check` | `check-shell` + `check-profiles` + `check-placeholders`. |
| `make check-shell` | ShellCheck every script, or `bash -n` when it is not installed. |
| `make check-profiles` | Assert every profile implements all nine `lang-*` targets. |
| `make check-placeholders` | List every `{{VAR}}` used and fail on one nothing binds. |
| `make check-pins` | Report action pins under `template/` that have fallen behind. |
| `make pin-actions` | Rewrite those pins to the newest release in the current major. |
| `make profiles` | List the available language profiles. |
| `make clean` | Remove `.scratch/`. |

`BOOTSTRAP_ARGS` passes extra flags through to the scaffolder:

```bash
make new TARGET=../MyTool PROFILE=python BOOTSTRAP_ARGS="--non-interactive --set PROJECT_SHORT=MT"
```

## `scripts/bootstrap.sh`

Renders `template/common/` and `template/<profile>/` into a target directory.

```
scripts/bootstrap.sh --target <dir> [options]
```

| Flag | Meaning |
| :--- | :--- |
| `--target <dir>` | **Required.** Destination directory, created if missing. |
| `--profile <name>` | `python`, `node`, `rust`, or `generic`. Prompted for if omitted. |
| `--answers <file>` | Load answers from a previously written `answers.env`. |
| `--set KEY=VALUE` | Override one variable. Repeatable. Wins over `--answers`. |
| `--merge` | Skip files that already exist. This is the default; the flag states it. |
| `--force` | Overwrite existing files. |
| `--dry-run` | Print what would be written; write nothing. |
| `--non-interactive` | Never prompt. Fails if a required value has no default. |
| `-h`, `--help` | Usage. |

**Precedence** for any variable, highest first: `--set`, `--answers`, an interactive answer, the
profile's `profile.env`, the built-in default.

**Exit codes**: `0` success, `1` a fatal error (unknown profile, missing required value in
non-interactive mode, unreadable answers file), `2` a usage error.

**Side effects**: writes into `--target` only. Also writes `<target>/.template/answers.env`, which
records every resolved variable so the same scaffold can be replayed. Appends the profile's
`.gitignore.append` fragment to `<target>/.gitignore`, guarded by a `# Profile: <name>` header so a
second run does not duplicate it. Never fetches anything over the network.

## `scripts/openssf-audit.sh`

Reads a repository and reports how close it is to the OpenSSF Best Practices badge.

```
scripts/openssf-audit.sh [path-to-repo] [--level passing|silver|gold] [--quiet]
```

| Flag | Meaning |
| :--- | :--- |
| `[path]` | Repository to audit. Defaults to the current directory. |
| `--level <level>` | Report only one badge level. Default: all three. |
| `--quiet` | Print only failures. |

**Result symbols**: `✔` satisfied, `✘` missing (with the remediation), `?` needs a human decision —
bus factor, coverage percentages, cryptographic choices. A criterion a script cannot honestly decide
is never silently passed.

**Exit codes**: `0` when nothing is missing, `1` otherwise. Suitable as a CI gate.

**Workflow safety.** Beyond the badge criteria, the audit reads every workflow it finds under any
`.github/workflows/` in the tree — a generated repository's own, and each profile's copy when run
against this repository — and reports:

| Check | Fails when |
| :--- | :--- |
| `dangerous_workflow` | `pull_request_target` is combined with a checkout of the PR's head ref. Reported as needing a human decision when the trigger is used without such a checkout. |
| `script injection` | An untrusted context (`github.event.pull_request.*`, `github.head_ref`, comment and issue bodies) is interpolated directly inside a `run:` block. |
| `token_permissions` | A workflow declares no top-level `permissions:` and so inherits the default token. |
| `pinned_dependencies` | A `uses:` reference names a tag or branch instead of a 40-character commit SHA. |

## `scripts/pin-actions.sh`

Refreshes the action SHA pins inside `template/`, which Dependabot does not traverse.

```
scripts/pin-actions.sh [--check] [--allow-major]
```

| Flag | Meaning |
| :--- | :--- |
| `--check` | Report stale pins and exit `1` if any. Writes nothing. |
| `--allow-major` | Consider releases beyond the current major version. |

Requires an authenticated `gh`. It reads the trailing version comment on each `uses:` line to decide
what "newer" means, so that comment is part of the data, not documentation. A pin whose comment is a
branch name is re-resolved to that branch's current head.

## The `lang-*` contract

A generated repository's `Makefile` knows nothing about its language. It calls these nine targets,
which the profile's `make/<profile>.mk` implements. [`profiles.md`](profiles.md) covers adding one.

| Target | Obligation |
| :--- | :--- |
| `lang-setup` | Bring a fresh checkout to a working development environment. |
| `lang-lint` | Lint, format-check, and type-check. Must fail on any finding. |
| `lang-format` | Auto-format and auto-fix in place. |
| `lang-test` | Fast unit tests. No network, no privileges. |
| `lang-test-integration` | Tests needing a real environment. |
| `lang-fuzz` | Property-based or fuzz tests. |
| `lang-audit` | Scan dependencies for known vulnerabilities. |
| `lang-build` | Produce release artifacts into `$(DIST_DIR)`. |
| `lang-clean` | Remove language-specific caches and artifacts. |

Each profile also ships a `profile.env` assigning `PRIMARY_LANGUAGE`, `PRIMARY_LANGUAGE_LOGO`,
`MIN_LANG_VERSION`, `CODEQL_LANGUAGE`, `DEPENDABOT_ECOSYSTEM`, `LINTER_NAME`, and `SKELETON_PATHS` —
the source directories written all-or-nothing, so a repository that already has its own source never
receives a test importing a module the scaffolder skipped.

## Placeholder substitution

`scripts/lib/render.sh` substitutes `{{KEY}}` using Bash parameter expansion over a fixed key list —
not `sed`, and not `eval`. Two consequences: a value containing slashes, ampersands, or quotes needs
no escaping, and a GitHub Actions expression such as `${{ github.ref }}` passes through untouched
because `github.ref` is not a bound key. [`placeholders.md`](placeholders.md) lists every key and
where its value comes from.
