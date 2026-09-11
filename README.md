<h1 align="center">TemplateRepository</h1>

<h4 align="center">A scaffolder that makes a new repository OSS-ready — governance, security policy, CI, and documentation — from the first commit.</h4>

<p align="center">
  <img src="https://img.shields.io/badge/OS-Linux-blue?style=for-the-badge&logo=linux" alt="Linux">
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Profiles-python%20%7C%20node%20%7C%20rust%20%7C%20generic-orange?style=for-the-badge" alt="Profiles">
  <img src="https://img.shields.io/badge/Target-OpenSSF%20Best%20Practices-green?style=for-the-badge" alt="OpenSSF">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#what-you-get">What You Get</a> •
  <a href="#language-profiles">Profiles</a> •
  <a href="#filling-the-documents-in-over-time">Filling Docs In</a> •
  <a href="#openssf-readiness">OpenSSF</a> •
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

Every project ends up needing the same twenty files: a `SECURITY.md` nobody wants to write twice, a
CI pipeline, a threat model, an ADR directory, a `Makefile` whose targets mean the same thing in
every repository. This repository holds that layer once, as a set of templates plus a scaffolder
that renders them into a new project.

## Quick Start

```bash
# A new project
make new TARGET=../MyNewTool PROFILE=python

# Preview without writing anything
make dry-run TARGET=../MyNewTool PROFILE=rust

# Add the missing layer to a repository that already exists (never overwrites)
make new TARGET=../ExistingRepo PROFILE=generic

# How close is any repository to the badge?
make audit REPO=../TransparentTorProxy
```

The scaffolder prompts for the project identity, or takes it from flags:

```bash
./scripts/bootstrap.sh --target ../MyNewTool --profile python --non-interactive \
  --set PROJECT_NAME="My New Tool" --set PROJECT_SHORT=MNT \
  --set PROJECT_DESC="One line that says what it does"
```

Answers are saved to `<target>/.template/answers.env` so the same values can be replayed later with
`--answers`.

## What You Get

A generated repository contains, all rendered with the project's own name, owner, and license:

| Area | Files |
| :--- | :---- |
| **Governance** | `GOVERNANCE.md`, `MAINTAINERS.md` (roles, access, bus factor, offboarding), `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md` (DCO, coding standards, test policy, Actions hardening), `SUPPORT.md` |
| **Security** | `SECURITY.md` (private disclosure, response SLA, scope), `SAST_POLICY.md`, `SCA_POLICY.md`, `SECRETS_POLICY.md`, `DYNAMIC_ANALYSIS_POLICY.md`, `HALL_OF_FAME.md`, `docs/security-assessment.md` (STRIDE skeleton) |
| **Documentation** | `docs/architecture.md`, `docs/interfaces.md`, `docs/verification.md`, `docs/documentation-policy.md` (which file to update for which change), ADR directory with a template, and a [Diátaxis](https://diataxis.fr/)-structured MkDocs Material site |
| **CI/CD** | `ci.yml`, `codeql.yml`, `scorecard.yml`, `dependency-review.yml`, `dco.yml`, `fuzzing.yml`, `docs.yml`, `stale.yml`, `release.yml` (SBOM + Sigstore signing + checksums) |
| **Repository hygiene** | `.gitignore`, `.gitattributes`, `.editorconfig`, `.markdownlint.yaml`, `.codacy.yml`, `.env.example`, `dependabot.yml`, `CODEOWNERS`, issue and pull request templates, `CITATION.cff` |
| **Build** | A `Makefile` that includes `make/*.mk` fragments, with the same target names in every project |

### The Makefile contract

The generated `Makefile` splits into language-agnostic orchestration and one language fragment:

```text
Makefile              identity variables, then includes:
├── make/common.mk    help, setup, install-hooks, verify, todo, clean
├── make/quality.mk   lint, lint-shell, lint-docs, lint-secrets, format, test, audit
├── make/docs.mk      docs-build, docs-serve, docs-sync, adr
├── make/release.mk   build, sbom, checksums, sign, release-check, release-dry
└── make/<profile>.mk lang-setup, lang-lint, lang-test, lang-build, …
```

Only the last file changes between languages. `make verify` means the same thing in a Rust project
and a Python one, which is the point: muscle memory transfers between repositories, and so does CI.

To support a language that has no profile yet, copy `template/generic/` and fill in the nine
`lang-*` targets. `make check-profiles` verifies that every profile implements the full contract.

## Language Profiles

| Profile | Toolchain | Ships |
| :------ | :-------- | :---- |
| `python` | Ruff, mypy, pytest, Hypothesis, pip-audit, hatchling | `pyproject.toml` with security lints (`flake8-bandit`), coverage config, `bump-my-version`, package skeleton, fuzz targets with tuned Hypothesis profiles |
| `node` | TypeScript, ESLint (type-aware), Prettier, Vitest | Strict `tsconfig`, flat ESLint config, coverage, build/pack targets |
| `rust` | Clippy (pedantic), rustfmt, proptest, cargo-audit | `Cargo.toml` with `unsafe_code = "forbid"`, overflow checks in release, MSRV job in CI |
| `generic` | Yours | A documented no-op implementation of the target contract, ready to fill in |

Every profile was generated and then actually run: `make lint`, `make test`, and `make build` pass
out of the box in each one.

## Filling the Documents In Over Time

A scaffold that demands twenty finished documents on day one gets abandoned on day one. Instead,
every section that needs project-specific content carries a marker:

```markdown
<!-- TODO(template): state the goal in two or three sentences, and the non-goals immediately after. -->
```

The markers are not "fill me in" stubs — each one says what belongs there and why, so the document
can be completed incrementally as the project takes shape:

```bash
make todo     # every remaining section, with file and line
```

`make release-check` refuses to tag a release while `README.md` or `SECURITY.md` still contains
markers, so the documents that users read first cannot ship unfinished.

## OpenSSF Readiness

```bash
make audit REPO=../MyProject
```

The audit maps [OpenSSF Best Practices criteria](https://www.bestpractices.dev/en/criteria) onto
concrete artifacts and reports each one as satisfied, missing, or needing a human decision — bus
factor and coverage thresholds are never assumed to pass. Findings come with the remediation.

A freshly generated repository satisfies 100% of the automatically checkable **passing** and
**silver** criteria, on every profile; what remains is the project-specific content the markers ask
for, plus the gold criteria that depend on having more than one maintainer.

The audit also reads the workflows themselves, which is where the expensive mistakes live: a
`pull_request_target` trigger combined with a checkout of the pull request's own code (Scorecard's
Dangerous-Workflow finding), untrusted input interpolated into a `run:` block, a missing
`permissions:` block, an action pinned to a movable tag. `pull_request_target` *without* an untrusted
checkout is reported as needing a human decision rather than quietly passed — it is legitimate, and
it is one edit away from not being.

## Repository Layout

```text
├── Makefile                  # scaffolder entrypoint — make help
├── scripts/
│   ├── bootstrap.sh          # renders template/ into a target repository
│   ├── openssf-audit.sh      # badge readiness report + workflow safety checks
│   ├── pin-actions.sh        # refreshes the action SHA pins under template/
│   └── lib/render.sh         # placeholder substitution engine
├── template/
│   ├── common/               # everything language-agnostic
│   ├── python/ node/ rust/   # language profiles
│   ├── generic/              # starting point for a new profile
│   └── licenses/             # license texts
├── tests/
│   ├── run-tests.sh          # the suite — scaffolds every profile and audits it
│   └── fixtures/             # a dangerous workflow, and its safe counterpart
└── docs/
    ├── usage.md              # full scaffolder reference
    ├── interfaces.md         # every flag, target, and file contract
    ├── profiles.md           # the lang-* contract, and how to add a profile
    ├── placeholders.md       # every {{VARIABLE}} and where it comes from
    └── openssf-checklist.md  # criterion-by-criterion mapping
```

## Maintaining the Template

```bash
make test               # end-to-end: scaffold every profile, audit what came out
make check              # shellcheck + profile contract + placeholder binding
make check-placeholders # every {{VAR}} used is bound by bootstrap.sh or a profile
make check-profiles     # every profile implements all nine lang-* targets
make check-pins         # action pins under template/ that have fallen behind
```

The template is verified through its output rather than its sources: `make test` scaffolds all four
profiles into a temporary directory and asserts that nothing is left unrendered, that the audit
reports zero missing criteria, and that replaying `answers.env` reproduces the repository
byte-for-byte. [`CONTRIBUTING.md`](CONTRIBUTING.md) covers adding a check.

Substitution is done with Bash parameter expansion over a fixed key list, not `sed`, so values
containing slashes need no escaping and GitHub Actions expressions such as `${{ github.ref }}` pass
through untouched.

Every action in every generated workflow is pinned to a commit SHA. Dependabot maintains this
repository's own pins but cannot see the copies under `template/`, so `make pin-actions` does that
job — it reads the version comment on each `uses:` line to decide what "newer" means.

## License

MIT. See [LICENSE](LICENSE).
