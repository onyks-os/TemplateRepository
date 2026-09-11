# Scaffolder Reference

Full reference for `scripts/bootstrap.sh`. For the short version, see the
[README](https://github.com/onyks-os/TemplateRepository#quick-start).

## Synopsis

```bash
scripts/bootstrap.sh --target <dir> [--profile <name>] [options]
```

| Option | Meaning |
| :----- | :------ |
| `--target <dir>` | Destination repository. Created if missing. **Required.** |
| `--profile <name>` | `python`, `node`, `rust`, or `generic`. Prompted for if omitted. |
| `--answers <file>` | Load values from a previously generated `answers.env`. |
| `--set KEY=VALUE` | Override one variable. Repeatable. Wins over `--answers`. |
| `--merge` | Skip files that already exist. This is the default. |
| `--force` | Overwrite existing files. |
| `--dry-run` | Print what would be written; change nothing. |
| `--non-interactive` | Never prompt. Fails if a required value has no default. |

## The three ways to run it

### A new project

```bash
make new TARGET=../MyNewTool PROFILE=python
```

You are prompted for the identity, ownership, and release values. Defaults come from `git config`
and from the target directory name, so pressing Enter through the whole prompt sequence produces a
sensible repository.

### An existing repository

```bash
make dry-run TARGET=../ExistingRepo PROFILE=generic   # look first
make new     TARGET=../ExistingRepo PROFILE=generic   # then apply
```

Existing files are never touched. The run ends with a list of what it skipped, so you can diff the
template's version against yours and merge by hand where it is worth it. Only `.gitignore` is
appended to rather than skipped, and only once — the profile block is marked with a
`# Profile: <name>` header that the script looks for before appending again.

Two consequences are worth knowing before you run it:

**The source skeleton is written all or not at all.** A profile ships a small package with a CLI
entry point plus the tests that import it. If the target already has source under the same name,
the whole skeleton — source, `tests/`, `fuzzing/` — is skipped, because writing only the tests
would leave them importing a module the scaffolder deliberately did not write. The paths that make
up the skeleton are declared per profile in `SKELETON_PATHS`.

**The `Makefile` is skipped, so the `make/*.mk` fragments land inert.** The fragments are written,
but your existing `Makefile` does not include them and nothing changes until you reconcile the two.
The migration that works:

```bash
# 1. Keep the identity block and the include chain from the template's Makefile.
#    template/common/Makefile is the reference; fill in your own project values.
# 2. Move every target that has no equivalent in the contract into make/project.mk,
#    which the generated Makefile already includes.
# 3. Extend a contract target by adding a prerequisite, never by redefining a recipe:

clean: clean-packages          # runs after the fragment's clean, no override warning
integration-test: docker-suite # adds to the contract target rather than replacing it
```

Redefining a target that a fragment already defines makes GNU Make print
`warning: overriding recipe for target` and silently discard the fragment's version. Adding a
prerequisite with no recipe is the supported way to extend one.

Expect the contract's gates to be stricter than what the repository had. `lint` runs the type
checker as well as the formatter, and `verify` is `lint test audit`; a project whose previous
`lint` was formatter-only will surface a backlog on the first run. That backlog is a finding, not a
reason to loosen the fragment.

### Replaying a previous run

Every run writes `<target>/.template/answers.env`. After the template gains a new file, re-running
with those answers adds it without re-asking anything:

```bash
scripts/bootstrap.sh --target ../MyTool --answers ../MyTool/.template/answers.env
```

Add `--force` to also refresh files that already exist — review the diff afterwards, since that
overwrites local edits.

## What happens during a run

1. The profile's `profile.env` is sourced, supplying language-derived values (`PRIMARY_LANGUAGE`,
   `CODEQL_LANGUAGE`, `DEPENDABOT_ECOSYSTEM`, …).
2. Missing values are prompted for, or taken from defaults in non-interactive mode.
3. Derived values are computed (`DOCS_URL`, `CRATE_NAME`, `PY_TARGET`, `COPYRIGHT_YEAR`, …).
4. `template/common/` is rendered into the target, then `template/<profile>/`.
5. The profile's `.gitignore.append` is appended to the base `.gitignore`.
6. The license text for `LICENSE_ID` is rendered from `template/licenses/`.
7. Answers are recorded, and the run reports unresolved placeholders and remaining
   `TODO(template)` markers.

Filenames are rendered too: the directory `__PKG__/` in the Python profile becomes the real package
directory, and any `{{VAR}}` in a path is substituted.

## Licenses

`template/licenses/` ships the MIT text. For any other SPDX identifier the scaffolder warns and
points at <https://spdx.org/licenses/>; drop the text in as `LICENSE` yourself, or add it to
`template/licenses/<SPDX-ID>.txt` so future runs pick it up automatically.

## After scaffolding

```bash
cd ../MyNewTool
git init && git add -A && git commit -s -m "chore: scaffold from TemplateRepository"
make setup          # create the environment and install dev dependencies
make install-hooks  # lint + tests run before every commit
make todo           # what is left to write
make verify         # the gate that CI also runs
```

Then, on GitHub:

1. Enable **private vulnerability reporting** (Settings → Code security). `SECURITY.md` already
   points at it.
2. Enable **secret scanning** and **push protection**.
3. Protect `main`: require a pull request, a passing CI check, and linear history.
4. Register the project at <https://www.bestpractices.dev/en/projects/new> and put the numeric ID in
   the README badge URL, replacing the `0` placeholder.
5. Consider pinning third-party Actions to commit SHAs — Dependabot's `github-actions` ecosystem is
   already configured to keep them current:

   ```bash
   gh api repos/actions/checkout/commits/v4 --jq .sha
   ```
