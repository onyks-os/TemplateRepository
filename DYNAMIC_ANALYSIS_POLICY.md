# Dynamic analysis policy

## Why this exists for a scaffolder

Reading `template/` tells you what the files contain. It does not tell you whether
`scripts/bootstrap.sh` renders them correctly, whether the result passes its own audit, or whether a
second run destroys the first. Those are properties of the *output*, and the only way to observe them
is to produce one.

So the dynamic analysis for this project is not an add-on to the test suite. It is the test suite:
`tests/run-tests.sh` runs the real scripts against real directories and inspects what came out.
Nothing is mocked, because there is nothing to mock — the unit under test is a program that writes
files.

## What is exercised

`make test` scaffolds all four profiles into a temporary directory and asserts:

| Property | Why it is checked at runtime |
| :--- | :--- |
| Every profile scaffolds and exits 0 | A profile can be internally consistent and still fail to render. |
| No `{{PLACEHOLDER}}` survives into the output | The one failure mode that makes a generated repository actively broken rather than merely incomplete. |
| The audit reports zero missing criteria | The README's central claim. Checked, not asserted. |
| A second run writes nothing | The scaffolder's core promise: it never destroys existing work. |
| `--dry-run` writes nothing | A preview that writes is worse than no preview. |
| `--force` does overwrite | The escape hatch has to actually work, or people reach for `rm -rf`. |
| Replaying `answers.env` is byte-identical | Reproducibility, and the property that makes a scaffold auditable after the fact. |
| An all-lowercase project name scaffolds non-interactively | A real regression: an empty acronym aborted the run. |
| The debt scan sees TODOs in an uncommitted repository | A real regression: `git grep` sees only tracked files, so a freshly scaffolded repository always looked clean. |
| The workflow-safety checks fire on a dangerous fixture | A check that never fails is not a check. |

The last one is the reason `tests/fixtures/` exists. `dangerous-workflow.yml` combines
`pull_request_target` with a checkout of the pull request's head, an unpinned action, a missing
top-level `permissions:` block, and an untrusted value interpolated into a `run:` block. The suite
asserts that all four checks report it. `safe-workflow.yml` is its counterpart: `pull_request_target`
with no untrusted checkout and the title passed through `env:`, and the suite asserts the audit refers
it to a human rather than either passing or failing it, and does not report it as an injection.

**Do not "fix" the dangerous fixture.** The suite asserts it stays broken.

## Fuzzing

Not run against this project, and the reason is worth stating rather than leaving as an omission. The
scaffolder's input is a set of named string variables supplied by the person running it, who already
has shell access — there is no privilege boundary for a fuzzer to cross. The property that would
matter, that a crafted value is substituted as text rather than executed, is structural: substitution
is Bash parameter expansion over a fixed key list, with no `eval` and no `sed`. That is verified by
reading `scripts/lib/render.sh`, which is twenty lines, and it is the first thing to re-verify if it
ever grows.

Repositories generated from this template do get fuzzing: `lang-fuzz` is part of the `lang-*`
contract, every language profile implements it, and `fuzzing.yml` runs it on every pull request plus a
weekly scheduled deep run.

## Running it

```bash
make test               # the full suite
make test VERBOSE=1     # plus the last bootstrap log on failure
```

It needs bash, git, and coreutils. Install ShellCheck as well — without it the suite falls back to
`bash -n`, which catches far less, and says so in its output rather than reporting a clean run.

Everything happens under `mktemp -d` and is removed on exit, including on failure. No test writes
inside the repository.

## Triage

A failure in `make test` blocks a merge. There is no flaky-test allowance: every check is
deterministic, offline, and reads only what the run itself produced.

When a check fails, fix the scaffolder or the template — not the assertion. If the assertion was
genuinely wrong, the commit that changes it says why in terms of what a generated repository should
look like.

When a bug is reported, the fix comes with a check in `tests/run-tests.sh` that fails without it.
Several checks in the table above exist because of exactly that, and they are labelled as regressions
so nobody deletes them for looking redundant.
