# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because this is a scaffolder, "changed" means *a repository generated after this release differs from
one generated before it*. A generated repository is a copy taken at a point in time; to pull a later
fix into one you already have, re-run `make new TARGET=<that-repo>` — existing files are never
overwritten.

## [Unreleased]

### Added

- **Workflow-safety checks in `scripts/openssf-audit.sh`.** The audit now reads workflows instead of
  only checking that they exist: it reports Dangerous-Workflow (`pull_request_target` combined with a
  checkout of the pull request's own code), script injection of untrusted context into `run:` blocks,
  missing top-level `permissions:`, and actions pinned to a movable tag instead of a commit SHA.
  `pull_request_target` *without* an untrusted checkout is reported as needing a human decision rather
  than passed or failed.
- **`scripts/pin-actions.sh`** — refreshes the action pins under `template/`, which Dependabot cannot
  reach. `--check` reports staleness without writing; the default stays within the current major.
- **A test suite for the template itself** (`tests/run-tests.sh`, `make test`). It scaffolds every
  profile into a throwaway directory and asserts on the result: nothing unrendered, zero missing audit
  criteria, `answers.env` replays byte-identically, the write modes behave as documented, and the
  workflow-safety checks fire on a deliberately dangerous fixture.
- **CI for this repository** — `make check`, the test suite, a self-audit, and CodeQL's `actions` pack
  over the workflows.
- **Governance for this repository**: `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`,
  `GOVERNANCE.md`, `MAINTAINERS.md`, this changelog, issue and pull request templates, `CODEOWNERS`
  routing `scripts/` and both workflow trees.
- **Security documentation for this repository**: `docs/security-assessment.md` (STRIDE, with the
  `pull_request_target` escalation path written out), `SAST_POLICY.md`, `DYNAMIC_ANALYSIS_POLICY.md`,
  and `docs/interfaces.md` as the flag-and-target reference.
- **OpenSSF Scorecard runs against this repository**, not only in what it generates.
- **A YAML check in the test suite**: every shipped `.yml` must parse as exactly one document.

### Changed

- **Every action in every shipped workflow is now pinned to a commit SHA**, with the version in a
  trailing comment. Previously they were pinned to tags (`actions/checkout@v4`), which
  `template/common/CONTRIBUTING.md` already told contributors never to do, and which costs a
  generated repository its OpenSSF Scorecard Pinned-Dependencies score.
- `dtolnay/rust-toolchain` is pinned by SHA with an explicit `toolchain:` input. The action selects
  its toolchain from the branch name, so pinning it without that input would have silently changed
  which Rust version the generated workflows install.
- The Actions security section of `template/common/CONTRIBUTING.md` now gives the three safe patterns
  for posting a privileged comment on a pull request, instead of only saying to avoid
  `pull_request_target`.
- `scripts/pin-actions.sh` picked up `sigstore/gh-action-sigstore-python` sitting five minor versions
  behind on first run; the shipped release workflows now pin v3.5.0.

### Fixed

- **`dependency-review.yml` shipped a feature that could not work.** It set
  `comment-summary-in-pr: on-failure` while declaring only `contents: read`, so the comment was never
  posted — and on a fork's pull request the `pull_request` trigger cannot grant the write permission
  it needs regardless. The visible fix for that is to switch the trigger to `pull_request_target`,
  which is exactly the Dangerous-Workflow trap. The option is gone, the findings go to the job summary,
  and the file explains why.
- **The audit's documentation-debt scan reported zero on any repository with nothing committed.** It
  used `git grep`, which only sees tracked files, so a repository scaffolded minutes earlier — the
  case the audit exists for — always looked clean. It now passes `--untracked`.
- The debt scan no longer reports the scaffolder's own sources as unrendered placeholders when the
  audit is run against this repository.
- **`.codacy.yml` shipped with a stray `---` in the middle**, so it parsed as two YAML documents and
  every consumer read only the first. The entire `engines:` block — which disables markdownlint — was
  silently dead in every generated repository. Found by the new YAML check, which now guards it.
- **The generic profile shipped no `tests/` directory**, so a repository generated from it failed the
  audit's `test` criterion: it was the one profile that did not reach the 100% the README claims.
- **A second `bootstrap.sh` run into an existing target exited 2 despite succeeding.** With nothing
  written, the report step handed `grep` a fabricated empty filename; `grep` exits 2 on a file it
  cannot open, and `set -e` aborted the script after it had already printed its summary. Merging
  template fixes into an existing repository — `make new TARGET=<existing-repo>`, the documented
  path — therefore reported failure to every caller that checked the status.
- **`bootstrap.sh` could not run non-interactively on a machine with no git identity.** `CONTACT_EMAIL`
  defaulted to `git config user.email`, and an empty default aborts a non-interactive run — so a CI
  runner or a fresh container could not scaffold at all. It now falls back to a `TODO(template)`
  marker, which is what `make todo` already surfaces.
- `scripts/bootstrap.sh` is clean under ShellCheck: a failing `cd` in the script-root resolution was
  masked by `readonly`'s exit status, `--merge` set a variable nothing read, and the profile list was
  parsed out of `ls`.

## [0.1.0] - 2026-09-08

### Added

- The scaffolder: `scripts/bootstrap.sh` renders `template/` into a target repository, prompting for
  the project identity or taking it from flags, and recording the answers for later replay.
- `scripts/openssf-audit.sh` — OpenSSF Best Practices readiness report for any repository, reporting
  each criterion as satisfied, missing, or needing a human decision.
- Four language profiles — python, node, rust, generic — behind a nine-target `lang-*` Makefile
  contract, so the rest of the generated repository does not know which language it is.
- The language-agnostic layer: security and governance policies, threat model, ADR directory, issue
  and pull request templates, CI, release signing with Sigstore, SBOM generation, MkDocs site.

[Unreleased]: https://github.com/onyks-os/TemplateRepository/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/onyks-os/TemplateRepository/releases/tag/v0.1.0
