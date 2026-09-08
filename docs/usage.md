# Scaffolder Reference

Full reference for `scripts/bootstrap.sh`. For the short version, see the
[README](../README.md#quick-start).

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
