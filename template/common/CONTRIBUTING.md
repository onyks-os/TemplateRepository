# Contributing to {{PROJECT_SHORT}}

First off, thank you for considering contributing to {{PROJECT_SHORT}}!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Report Bugs](#how-to-report-bugs)
- [How to Propose Features](#how-to-propose-features)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Architectural Principles](#architectural-principles)
- [Testing](#testing)
- [Documentation Requirements](#documentation-requirements)
- [Developer Certificate of Origin (DCO)](#developer-certificate-of-origin-dco)
- [Pull Request Process](#pull-request-process)
- [Security Best Practices for GitHub Actions](#security-best-practices-for-github-actions)

## Code of Conduct

By participating in this project you agree to abide by the
[Code of Conduct](CODE_OF_CONDUCT.md). Report unacceptable behavior to `{{CONTACT_EMAIL}}`.

## How to Report Bugs

- **Check existing issues** — someone may have reported it already.
- **Use the issue template** and provide as much detail as possible.
- **Include diagnostics**: version, operating system, exact command, and full output.

## How to Propose Features

- Open an issue using the *Feature request* template.
- Explain **why** the feature is needed and how it fits the project's goals, not only what it does.
- Wait for maintainer feedback before investing significant implementation time.

## Development Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}.git
   cd {{PROJECT_SLUG}}
   ```

2. **Bootstrap the environment**:

   ```bash
   make setup
   ```

3. **Install the Git pre-commit hook** (runs lint + unit tests before each commit):

   ```bash
   make install-hooks
   ```

4. **Run the test suite**:

   ```bash
   make test
   ```

## Coding Standards

All contributions must satisfy the following before being submitted. These checks are enforced
automatically by the CI pipeline.

- **Linting & formatting**: the code must pass `make lint` with no errors or warnings.
- **Shell scripts**: everything under `scripts/` must pass `shellcheck`.
- **Type annotations**: new functions and methods must be fully annotated, consistent with the
  existing codebase.
- **No dead code**: remove unused imports, variables, and commented-out blocks before submitting.
- **Commit messages**: follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`).

> Pull requests that fail `make lint` will not be merged.

## Architectural Principles

<!-- TODO(template): replace these with the principles that actually govern this codebase. -->

1. **Single Responsibility Principle (SRP)**: each module does one thing. Keep presentation logic out
   of core logic.
2. **No UI coupling**: core modules must not import the CLI/UI layer. Use callbacks or return raw data.
3. **Atomic operations**: state-changing operations must be all-or-nothing; never leave the system
   half-configured.
4. **Crash safety**: always consider what happens if the process is killed mid-operation.
5. **Test-driven development**: every new feature or bug fix ships with a corresponding test.

## Testing

- **Unit tests** must pass on every pull request. They are fully mocked and require no privileges.
- **Integration tests** run in a container or VM and verify real system behavior.

### When Tests Run

- **Pull requests**: every pull request triggers the CI pipeline — linting, static analysis, and the
  unit test matrix.
- **Push to `main`**: the same suite runs on any push to the default branch.
- **Locally**: run `make verify` before opening a pull request.

### Interpreting Results

- **Green**: ready for review.
- **Red**: blocks the merge. Review the logs, fix, and push an update.

### Test Policy for Major Changes

A change is **major** if it adds a significant feature, alters a security boundary, or changes the
crash-safety architecture. For major changes the contributor **must**:

- Add new unit tests covering the functionality.
- Update existing tests when the expected behavior changes.
- Run the integration suite manually and report the result in the pull request.

Pull requests are blocked from merging if tests do not sufficiently cover the change.

## Documentation Requirements

Every change must keep the documentation in sync with the code. The exact files to update for each
type of change are defined in **[`docs/documentation-policy.md`](docs/documentation-policy.md)**.
At minimum, every user-visible change requires a [`CHANGELOG.md`](CHANGELOG.md) entry.

## Developer Certificate of Origin (DCO)

By contributing to {{PROJECT_SHORT}} you certify that you have the right to submit the contribution
under the project's {{LICENSE_ID}} license, and you agree to the
[Developer Certificate of Origin v1.1](https://developercertificate.org/).

**Every commit must include a `Signed-off-by` line** with your real name and email:

```
Signed-off-by: Jane Doe <jane@example.com>
```

The easiest way to add it is the `-s` flag:

```bash
git commit -s -m "your commit message"
```

For multiple commits in a branch, sign them off at once:

```bash
git rebase --signoff HEAD~<number-of-commits>
```

> Pull requests with unsigned commits will not be merged. The DCO check is enforced by CI.

<details>
<summary>Full DCO text</summary>

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

</details>

## Pull Request Process

1. Create a branch from `main`.
2. Ensure `make verify` passes locally.
3. Update the documentation required by [`docs/documentation-policy.md`](docs/documentation-policy.md).
4. Fill in the pull request template checklist honestly.
5. Submit the pull request and wait for review. Expect a first response within **7 days**.

Thank you for your help!

---

## Security Best Practices for GitHub Actions

When contributing workflows or modifying CI pipelines, follow these guidelines to prevent injection
attacks.

### 1. Never interpolate untrusted data directly into shell commands

**Bad** (vulnerable to script injection):

```yaml
- run: echo "PR title: ${{ github.event.pull_request.title }}"
```

**Good** (use environment variables):

```yaml
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "PR title: $PR_TITLE"
```

### 2. Never combine `pull_request_target` with a checkout of the pull request

`pull_request_target` runs in the context of the **base** repository: it sees the repository secrets
and gets a token that can write to this repository, even when the pull request comes from a fork.
That is deliberate — it is the only way a fork's PR can be commented on or labelled. It becomes a
full repository compromise the moment the same workflow also checks out the fork's code:

```yaml
# NEVER DO THIS — a fork's code runs with a token that can push to this repository.
on: pull_request_target
permissions:
  pull-requests: write
jobs:
  test:
    steps:
      - uses: actions/checkout@...
        with:
          ref: ${{ github.event.pull_request.head.sha }}   # untrusted code
      - run: make test                                      # ...executed with write access
```

Anything the pull request controls counts as "the fork's code": not just `ref:` on the checkout, but
build scripts, `Makefile` targets, test fixtures, `package.json` lifecycle hooks, and pre-commit
configuration. OpenSSF Scorecard reports this pattern as **Dangerous-Workflow**.

**How this usually gets introduced.** A reporting job — SAST, SCA, coverage — is asked to comment its
result on the pull request. That needs `pull-requests: write`, and on the `pull_request` trigger a
fork's token is read-only regardless of the `permissions:` block, so the comment never appears. The
first search result says to switch the trigger to `pull_request_target`, and the checkout is already
sitting in the file. Nobody adds an exploit; the workflow just drifts into one.

**Use one of these three instead.**

1. **Do without the comment.** Every reporting action already writes to `$GITHUB_STEP_SUMMARY`, which
   is visible on the checks tab and needs no write permission at all. This is what
   `.github/workflows/dependency-review.yml` does, and it is the right default.

2. **Split privilege from execution with `workflow_run`.** The untrusted job runs under
   `pull_request` with no permissions and uploads its result as an artifact. A second workflow,
   triggered by `workflow_run`, holds the write permission, downloads that artifact, and posts the
   comment — without ever checking out the pull request:

   ```yaml
   # report.yml — privileged, and touches no untrusted code.
   on:
     workflow_run:
       workflows: ["CI"]
       types: [completed]
   permissions:
     pull-requests: write
   jobs:
     comment:
       runs-on: ubuntu-latest
       steps:
         # No actions/checkout of the head ref. Only the artifact is read,
         # and it is treated as data: never `run:` anything it contains.
         - uses: actions/download-artifact@...
           with:
             run-id: ${{ github.event.workflow_run.id }}
             github-token: ${{ secrets.GITHUB_TOKEN }}
             name: report
   ```

3. **`pull_request_target` with zero checkout of untrusted code.** Legitimate when the job only reads
   pull request metadata through the API — labelling, size checks, the dependency graph. The rule is
   absolute: no `actions/checkout` of the head ref, and no execution of any file the pull request can
   change. If the workflow needs the PR's file contents, it is the wrong tool.

Whichever you pick, keep the privileged workflow short enough to audit in one screen, and remember
that artifacts from an untrusted run are attacker-controlled data — parse them, never execute them.

### 3. Pin actions to a full commit SHA

Actions must be pinned to an immutable commit SHA, not a mutable tag or branch. A tag can be moved to
point at different code after review; a SHA cannot. This applies to first-party actions too, because
`actions/checkout@v4` is just as mutable as any other tag:

```yaml
- uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
```

Keep the human-readable version in a trailing comment — Dependabot reads it, and updates both the SHA
and the comment together on the weekly `github-actions` run configured in `.github/dependabot.yml`.

A major bump of a first-party action is usually a runtime change — Node 20 to Node 24, say — rather
than an input change. It is still a breaking change for **self-hosted runners**, which must meet the
minimum runner version the release names before the workflow will run at all. GitHub-hosted runners
are already there.

Actions that select their behaviour from the ref name need that behaviour restated as an input once
the ref is a SHA. `dtolnay/rust-toolchain@stable` becomes a pinned SHA plus an explicit
`toolchain: stable`, otherwise the pin silently changes which toolchain is installed.

### 4. Limit `GITHUB_TOKEN` permissions

Declare the minimum permissions at workflow level:

```yaml
permissions:
  contents: read
```

### 5. Sanitize inputs from issue and comment bodies

If user-provided text must be used, validate it against an allowlist or escape it before passing it
to a script.

### 6. Run untrusted code in isolated containers

For actions that execute code from pull requests, run them inside a container with no access to
secrets.

### Reference

- [GitHub Security Hardening for Actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
