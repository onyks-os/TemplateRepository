<!--
Copyright (c) {{COPYRIGHT_YEAR}} {{GITHUB_OWNER}}
SPDX-License-Identifier: {{LICENSE_ID}}
-->

# Dependency Policy and Reference

This document is the authoritative inventory of every dependency {{PROJECT_SHORT}} relies on, and the
policies governing how dependencies are selected, pinned, monitored, and upgraded.

---

## 1. Dependency Directory

### 1.1 Runtime Dependencies

| Package | Version constraint | License | Purpose | Security justification |
| :------ | :----------------- | :------ | :------ | :--------------------- |
| <!-- TODO(template): one row per direct runtime dependency. --> | | | | |

### 1.2 Development Dependencies

| Package | Version constraint | License | Purpose |
| :------ | :----------------- | :------ | :------ |
| <!-- TODO(template): linters, test frameworks, build tooling. --> | | | |

### 1.3 System-Level Dependencies

| Package | Minimum version | Provided by | Purpose |
| :------ | :-------------- | :---------- | :------ |
| <!-- TODO(template): binaries and system libraries invoked at runtime. --> | | | |

### 1.4 Optional & Dynamic Dependencies

| Package | When required | Degradation if absent |
| :------ | :------------ | :-------------------- |
| <!-- TODO(template): extras and lazily-imported packages. --> | | |

---

## 2. Dependency Management Policies

### 2.1 Dependency Vetting and Selection

Before a new dependency is added, it must satisfy all of the following:

1. **Necessity**: the functionality cannot be implemented in a reasonable amount of first-party code.
2. **Maintenance**: the project has had a release or substantive commit within the last 12 months.
3. **License compatibility**: the license is compatible with {{LICENSE_ID}} (see [SCA_POLICY.md](SCA_POLICY.md)).
4. **Transitive weight**: the dependency does not pull in a disproportionate transitive tree.
5. **Provenance**: the package is published by its upstream maintainers, not a third-party mirror.

The rationale for each accepted dependency is recorded in the tables above.

### 2.2 Version Pinning & Range Rules

- **Applications**: dependencies are pinned to exact versions in the lockfile, which is committed.
- **Libraries**: dependencies declare a minimum version and an upper bound at the next major.
- **CI actions**: pinned to a full commit SHA.

### 2.3 Vulnerability Monitoring & Remediation

- Dependabot monitors the manifest and opens update pull requests automatically.
- `make audit` runs the ecosystem's vulnerability scanner locally and in CI.
- Remediation timelines are defined in [SCA_POLICY.md](SCA_POLICY.md).

### 2.4 Upgrading Dependencies

1. Read the upstream changelog for breaking changes.
2. Run `make verify` against the upgrade.
3. Record the upgrade in [`CHANGELOG.md`](CHANGELOG.md) and update the tables above.

### 2.5 Software Bill of Materials (SBOM)

A CycloneDX SBOM is generated and attached to every release; see
[`.github/workflows/release.yml`](.github/workflows/release.yml) and
[`docs/verification.md`](docs/verification.md).
