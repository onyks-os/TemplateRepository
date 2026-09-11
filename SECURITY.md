# Security Policy

## What this repository is, and what that means for security

TemplateRepository is a scaffolder: `scripts/bootstrap.sh` renders the files under `template/` into a
directory you name, and `scripts/openssf-audit.sh` reads a repository and reports on it. Both run on
your machine, with your permissions, and the first one writes files. That is the trust boundary worth
thinking about — not a service, but a script you are about to run against a directory you care about.

Two consequences follow, and both are deliberate:

- **The scaffolder never overwrites an existing file** unless you pass `--force`. Run it with
  `--dry-run` first against any directory that already has content.
- **What it writes, it writes from `template/`** — there is no network fetch at scaffold time, so what
  you review in this repository is exactly what lands in yours.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

Use GitHub's private vulnerability reporting:

1. Go to <https://github.com/onyks-os/TemplateRepository/security/advisories>
2. Click **Report a vulnerability**
3. Include what you did, what happened, and what you expected — a reproduction against a throwaway
   directory is worth more than a description.

## What to expect

- An acknowledgment within **48 hours**.
- Progress updates at least every **7 days** while the report is open.
- Credit in the release notes when a fix ships, unless you would rather stay anonymous.

## What counts as a vulnerability here

In scope, and treated as security issues:

- Any path by which `bootstrap.sh` writes outside the directory passed as `--target`, or overwrites a
  file without `--force`.
- Any way a crafted value — a project name, an `answers.env`, a `--set` override — causes command
  execution rather than being substituted as text. Substitution uses Bash parameter expansion over a
  fixed key list rather than `eval` or `sed`, and a bypass of that is a real finding.
- A workflow shipped in `template/` that grants a privilege it does not need, or that runs code a
  pull request controls with a writable token. `scripts/openssf-audit.sh` checks for this class and
  `tests/run-tests.sh` asserts the checks fire, but a case that slips past both is a finding.
- A dependency pin in `template/` that points at a commit which is not what its version comment says.

Out of scope:

- `TODO(template)` markers and unfilled sections in a generated repository. Those are the scaffolder
  working as intended; `make todo` lists them.
- Findings that require you to already be able to run arbitrary commands as the user running the
  script.
- The security posture of a repository *generated* from this template — report those to that project.
  Systematic weaknesses in what the template generates, however, belong here.

## Supported versions

The `main` branch is the supported version. This is a scaffolder: a generated repository is a copy
taken at a point in time, and fixes land in `main` for the next scaffold rather than being backported.
If a fix matters for a repository you already generated, `make new TARGET=<existing-repo>` merges the
corrected files in without touching anything you have written — see `docs/usage.md`.
