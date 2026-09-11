# TemplateRepository

TemplateRepository is a scaffolder. It renders the layer every serious repository needs — governance,
security policy, CI, release automation, and a documentation site — into a new or existing project,
so none of it has to be rewritten by hand a second time.

[Scaffold a Repository](usage.md){ .md-button .md-button--primary }
[Language Profiles](profiles.md){ .md-button }
[GitHub Repository](https://github.com/onyks-os/TemplateRepository){ .md-button }

---

!!! info "It merges, it does not overwrite"
    Pointed at a repository that already exists, the scaffolder writes only the files that are
    missing. Nothing you have already written is replaced, so running it against a live project is
    an additive operation.

---

## What It Renders

<div class="grid cards" markdown>

- **Governance**

    ---

    `GOVERNANCE.md`, `MAINTAINERS.md` (roles, access, bus factor, offboarding), `CODE_OF_CONDUCT.md`,
    `CONTRIBUTING.md` with the DCO, coding standards and test policy, and `SUPPORT.md`.

- **Security Policy**

    ---

    `SECURITY.md` with a private disclosure route and a response SLA, plus the SAST, SCA, secrets and
    dynamic-analysis policies and a STRIDE skeleton in `docs/security-assessment.md`.

- **CI/CD**

    ---

    `ci.yml`, `codeql.yml`, `scorecard.yml`, `dependency-review.yml`, `dco.yml`, `fuzzing.yml`,
    `docs.yml`, `stale.yml`, and a `release.yml` that produces an SBOM, checksums and Sigstore
    signatures.

- **A Makefile Contract**

    ---

    The same target names in every repository: `verify`, `lint`, `test`, `docs-build`,
    `release-check`. Language specifics live behind a single `lang-*` fragment.

</div>

## The Two Commands

```bash
# A new project
make new TARGET=../MyNewTool PROFILE=python

# How close is any repository to the OpenSSF badge?
make audit REPO=../TransparentTorProxy
```

`make dry-run` takes the same arguments and writes nothing.

## Where To Go Next

| You want to | Read |
| :--- | :--- |
| Run the scaffolder | [Scaffold a Repository](usage.md) |
| Know what each script and target does | [Interfaces](interfaces.md) |
| See which variables get substituted | [Placeholders](placeholders.md) |
| Compare `python`, `node`, `rust`, `generic` | [Language Profiles](profiles.md) |
| Understand what the scaffolder trusts | [Security Assessment](security-assessment.md) |
| Map the output to the OpenSSF badge | [OpenSSF Criterion Mapping](openssf-checklist.md) |
