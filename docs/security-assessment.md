# Security assessment

## What is being assessed

TemplateRepository is two Bash programs and a directory of files they copy. There is no service, no
network listener, and no persistent state. The security question is therefore narrow and concrete:

> You are about to run a script, with your own permissions, that writes files into a directory you
> care about — and whose output becomes the security posture of a repository you will publish.

Two assets follow from that, and they are the only two that matter:

1. **The target directory.** Work you have already done, which the scaffolder must not destroy.
2. **The generated repository's security posture.** A weakness in `template/` is inherited by every
   project scaffolded from it, and nobody re-reviews a file that arrived looking finished.

The second asset is the unusual one. A defect here does not fail loudly in this repository; it ships
quietly in the next twenty.

## Trust boundaries

| Boundary | Crossing it |
| :--- | :--- |
| Operator → scaffolder | Command-line flags, interactive answers, `answers.env`. Supplied by the person running it, who already has shell access — so these are trusted for *privilege*, but not for *correctness*. |
| `template/` → generated repository | Every file rendered. Reviewed here, once, on behalf of every future project. |
| Generated repository → GitHub Actions | The workflows the template ships run with a token in a repository the operator does not fully control. |
| Scaffolder → network | None. Nothing is fetched at scaffold time. `pin-actions.sh` does talk to the GitHub API, but it is a maintenance tool, never part of scaffolding. |

## STRIDE

### Spoofing

Not applicable to the scaffolder: it has no authentication and no notion of identity. It is relevant
to what the scaffolder *generates*. The release workflow signs artifacts with Sigstore keyless
signing, so a release is bound to the workflow and tag that produced it rather than to a long-lived
key somebody can steal. Verification is documented in the generated `docs/verification.md`.

### Tampering

**The target directory.** The scaffolder writes only under `--target`, and skips any file that
already exists unless `--force` is passed. `--dry-run` shows the full write set first. The test suite
asserts all three behaviours. Path traversal is not a live concern because every destination path is
built from `template/`'s own tree, which is a reviewed artifact of this repository, not from operator
input — but a rendered path that escaped `--target` would be a vulnerability, and `SECURITY.md` says
so explicitly.

**The supply chain of what is generated.** Every action in every shipped workflow is pinned to a
commit SHA rather than a tag. A tag is a movable pointer: whoever controls the action's repository can
re-point `v4` at different code after it was reviewed here, and every repository scaffolded from this
template would pick that up. `tests/run-tests.sh` fails on an unpinned action, and
`scripts/pin-actions.sh` keeps the pins current without requiring anyone to un-pin them to do it.

### Repudiation

The generated repository enforces the Developer Certificate of Origin on every commit through
`.github/workflows/dco.yml`, and this repository holds itself to the same rule. The scaffolder writes
`<target>/.template/answers.env`, which records exactly what was rendered and makes a scaffold
reproducible after the fact.

### Information disclosure

The scaffolder reads nothing outside `template/` and the answers it is given. It has no logging,
sends nothing anywhere, and never writes outside the target.

The relevant exposure is that answers become public: `CONTACT_EMAIL` and `SECURITY_EMAIL` are rendered
into `SECURITY.md`, `CODE_OF_CONDUCT.md`, and `CITATION.cff` in a repository that will be published.
That is intended — a security policy needs a reachable contact — but it is worth knowing before
answering, and `docs/placeholders.md` records which values end up in published files.

### Denial of service

Out of scope. A local script that writes a fixed number of files has no availability property worth
defending; the operator can stop it.

### Elevation of privilege

**In the scaffolder.** Placeholder substitution is the only place operator input meets execution, and
it is done with Bash parameter expansion over a fixed key list — not `eval`, not `sed`. A value
containing `$(...)`, backticks, slashes, or quotes is substituted as text. A bypass of that is the
highest-severity finding this project can receive, and `SECURITY.md` names it as such.

**In what is generated.** This is where the real risk concentrates, and it has a specific shape. A
workflow that needs to comment its results on a pull request needs `pull-requests: write`; on the
`pull_request` trigger a fork's token is read-only regardless of what the workflow declares, so the
comment never appears; the obvious remedy is `pull_request_target`, which runs with the base
repository's token — and if the workflow also checks out the pull request's head, the fork's code now
executes with write access to the repository. Nobody writes that deliberately. It is assembled one
reasonable step at a time.

The mitigations are layered because a single one would rot:

- Nothing shipped in `template/` uses `pull_request_target` at all, and the test suite asserts it.
- `dependency-review.yml` — the workflow that would most naturally want a PR comment — ships without
  the comment option, and carries a comment explaining why, so the next maintainer meets the reasoning
  before they meet the temptation.
- `scripts/openssf-audit.sh` reports the combination as a failure, `pull_request_target` alone as a
  decision for a human, and also flags untrusted interpolation into `run:` blocks and missing
  `permissions:` blocks.
- `tests/fixtures/` holds a deliberately dangerous workflow and its safe counterpart, so the checks
  themselves are tested rather than assumed.
- `template/common/CONTRIBUTING.md` documents the three safe patterns, because a rule that only says
  "don't" gets worked around by whoever needs the feature.

## Residual risk

- **A generated repository is a copy.** A fix landing here does not reach repositories already
  scaffolded. Re-running `make new` against an existing repository merges corrected files in without
  overwriting anything, but it is a manual step, and nothing notifies anyone that it is due.
- **The audit checks shape, not intent.** It can see that a workflow checks out a PR head under a
  privileged trigger. It cannot see that a `make test` target in a generated repository was later
  pointed at a script the pull request controls. `pull_request_target` is reported to a human for
  exactly this reason.
- **Pin freshness is manual.** Dependabot cannot see the workflows under `template/`.
  `make check-pins` reports staleness, but somebody has to run it.
- **Bus factor is one.** Acknowledged in the OpenSSF gold criteria as unmet.
