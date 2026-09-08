# OpenSSF Best Practices — Criterion Mapping

How each [OpenSSF Best Practices criterion](https://www.bestpractices.dev/en/criteria) is satisfied
by a repository generated from this template, and what is left for you.

Run the report at any time:

```bash
make audit REPO=../MyProject              # everything
make audit REPO=../MyProject LEVEL=silver # one level
```

The audit answers what a script can answer. Criteria that depend on human judgement — bus factor,
coverage thresholds, cryptographic design — are reported as **MANUAL** rather than assumed to pass,
because a checklist that lies to you is worse than no checklist.

## Passing

| Criterion | Satisfied by | Left to you |
| :-------- | :----------- | :---------- |
| `description_good` | `README.md` | Replace the `TODO(template)` markers with the real description |
| `interact`, `contribution`, `contribution_requirements` | `CONTRIBUTING.md` | — |
| `license_location`, `floss_license` | `LICENSE`, `LICENSE_ID` | Choose a license if not MIT |
| `documentation_basics`, `documentation_interface` | `docs/`, `docs/interfaces.md` | Fill in the interface tables |
| `sites_https` | GitHub + GitHub Pages | — |
| `report_process`, `report_tracker` | `SECURITY.md`, `.github/ISSUE_TEMPLATE/` | — |
| `vulnerability_report_private` | GitHub private advisories | Enable it in repository settings |
| `vulnerability_report_response` | 48-hour commitment in `SECURITY.md` | Honor it |
| `version_unique`, `version_semver`, `release_notes` | `CHANGELOG.md` (Keep a Changelog + SemVer) | Keep it current |
| `build`, `build_common_tools` | `Makefile` | — |
| `test`, `test_invocation` | `tests/`, `make test` | Write real tests |
| `automated_integration_testing`, `test_continuous_integration` | `.github/workflows/ci.yml` | — |
| `test_policy`, `tests_are_added` | Test policy in `CONTRIBUTING.md` | Enforce it in review |
| `warnings`, `warnings_fixed` | `make lint`, warnings-as-errors in CI | — |
| `know_secure_design`, `know_common_errors` | `docs/security-assessment.md` | Complete the STRIDE tables |
| `static_analysis` | `.github/workflows/codeql.yml`, `SAST_POLICY.md` | — |
| `dynamic_analysis` | `.github/workflows/fuzzing.yml`, `DYNAMIC_ANALYSIS_POLICY.md` | List the real fuzz targets |
| `dependency_monitoring` | `.github/dependabot.yml` | — |
| `crypto_*` | — | **MANUAL**: answer on bestpractices.dev if you use cryptography |
| `vulnerabilities_fixed_60_days` | — | **MANUAL**: your response discipline |

## Silver

| Criterion | Satisfied by | Left to you |
| :-------- | :----------- | :---------- |
| `governance`, `roles_responsibilities` | `GOVERNANCE.md`, `MAINTAINERS.md` | — |
| `code_of_conduct` | `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1) | — |
| `access_continuity` | `.github/CODEOWNERS`, access table in `MAINTAINERS.md` | List the security-critical paths |
| `dco` | `CONTRIBUTING.md` + `.github/workflows/dco.yml` | — |
| `documentation_architecture` | `docs/architecture.md` | Fill it in |
| `documentation_security` | `docs/security-assessment.md` | Fill it in |
| `documentation_quick_start` | `docs/web/tutorials/quickstart.md` | Fill it in |
| `documentation_roadmap` | `ROADMAP.md` | Fill it in |
| `documentation_achievements` | `docs/decisions/` | Write ADRs as you go — `make adr` |
| `signed_releases` | Sigstore keyless signing in `release.yml` | — |
| `sbom` | CycloneDX generation in `release.yml` | — |
| `dependency_policy` | `DEPENDENCIES.md`, `SCA_POLICY.md` | Fill in the dependency tables |
| `secrets_policy` | `SECRETS_POLICY.md`, `make lint-secrets` | Enable push protection |
| `installation_common`, `installation_development_quick` | `make setup`, MkDocs site | — |
| `test_statement_coverage_80` | `make coverage` | **MANUAL**: reach the threshold |
| `two_person_review` | — | **MANUAL**: needs a second maintainer |

Beyond the criteria, the template also ships `scorecard.yml` and `dependency-review.yml`, which are
not badge requirements but feed the [OpenSSF Scorecard](https://scorecard.dev/) badge and block
pull requests that introduce a vulnerable or incompatibly licensed dependency.

## Gold

Gold is mostly organizational rather than technical, and a solo project cannot reach it by adding
files:

| Criterion | Status |
| :-------- | :----- |
| `bus_factor >= 2` | **MANUAL** — recruit a second maintainer, then list them in `MAINTAINERS.md` |
| `code_review_standards`, all changes reviewed | **MANUAL** — enable branch protection requiring review |
| `test_statement_coverage_90`, `test_branch_coverage_80` | **MANUAL** — `make coverage` |
| `build_reproducible` | Partly: `docs/verification.md` documents the procedure; you must confirm and state the result |
| `hardening` | `SAST_POLICY.md`, workflow permissions declared read-only by default |
| `signed_releases` with SBOM | Satisfied by `release.yml` |

## Registering

1. Go to <https://www.bestpractices.dev/en/projects/new> and add the repository.
2. Note the numeric project ID from the URL.
3. Replace the `0` in the README badge URLs (`/projects/0` and `/cii/level/0`) with it, or re-run
   the scaffolder with `--set OPENSSF_PROJECT_ID=<id>`.
4. Work through the questionnaire; `make audit` tells you which answers you can already justify.
