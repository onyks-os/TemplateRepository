<!--
Copyright (c) {{COPYRIGHT_YEAR}} {{GITHUB_OWNER}}
SPDX-License-Identifier: {{LICENSE_ID}}
-->

# {{PROJECT_SHORT}} — Security Assessment & Threat Model

This is the single source of truth for the {{PROJECT_SHORT}} threat model. Operational reporting
procedures live in [`SECURITY.md`](../SECURITY.md).

## Table of Contents

1. [Security Objectives](#1-security-objectives)
2. [Trust Boundaries & Assets](#2-trust-boundaries--assets)
3. [Threat Model (STRIDE)](#3-threat-model-stride)
4. [Known Limitations & Residual Risks](#4-known-limitations--residual-risks)
5. [Supply Chain Security](#5-supply-chain-security)
6. [Security Controls Summary](#6-security-controls-summary)
7. [Out of Scope](#7-out-of-scope)

---

## 1. Security Objectives

<!-- TODO(template): state what the project guarantees, in falsifiable terms. Each objective should
     be something an attacker could demonstrably break. -->

| # | Objective | Rationale |
| :- | :-------- | :-------- |
| O1 | <!-- TODO --> | <!-- TODO --> |

---

## 2. Trust Boundaries & Assets

### 2.1 Trust Boundaries

<!-- TODO(template): every point where data or control crosses a privilege level. -->

| Boundary | Untrusted side | Trusted side | Validation performed |
| :------- | :------------- | :----------- | :------------------- |
| B1 | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

### 2.2 Protected Assets

| Asset | Confidentiality | Integrity | Availability |
| :---- | :-------------- | :-------- | :----------- |
| <!-- TODO --> | | | |

---

## 3. Threat Model (STRIDE)

For each component, enumerate threats under **S**poofing, **T**ampering, **R**epudiation,
**I**nformation disclosure, **D**enial of service, and **E**levation of privilege.

### 3.1 `<!-- TODO(template): component -->`

| STRIDE | Threat | Severity | Mitigation | Status |
| :----- | :----- | :------- | :--------- | :----- |
| T | <!-- TODO --> | High | <!-- TODO --> | Implemented |

---

## 4. Known Limitations & Residual Risks

<!-- TODO(template): risks that are accepted rather than mitigated, with the reasoning. An honest
     list here is worth more than a longer mitigation table. -->

| Risk | Severity | Why it is accepted | Compensating control |
| :--- | :------- | :----------------- | :------------------- |
| <!-- TODO --> | | | |

---

## 5. Supply Chain Security

### 5.1 Release Artifact Integrity

- Every release ships a `SHA256SUMS` file covering all artifacts.
- Artifacts are signed with Sigstore keyless signing via the release workflow.
- A CycloneDX SBOM is attached to each release.
- Verification instructions: [`docs/verification.md`](verification.md).

### 5.2 Dependency Monitoring

- Dependabot monitors the manifests and the GitHub Actions workflows.
- `make audit` runs the vulnerability scanner in CI on every pull request.
- Remediation thresholds: [`SCA_POLICY.md`](../SCA_POLICY.md).

### 5.3 Trusted Code Paths

- All GitHub Actions are pinned to full commit SHAs.
- `GITHUB_TOKEN` permissions are declared read-only at workflow level and elevated per job only when
  required.
- Branch protection requires review and passing status checks before merge.

---

## 6. Security Controls Summary

| Control | Type | Where implemented | Verified by |
| :------ | :--- | :---------------- | :---------- |
| Input validation | Preventive | <!-- TODO --> | <!-- TODO --> |
| Least privilege | Preventive | <!-- TODO --> | <!-- TODO --> |
| Fail-closed defaults | Preventive | <!-- TODO --> | <!-- TODO --> |
| Static analysis | Detective | CodeQL, linter | CI |
| Dependency scanning | Detective | Dependabot, `make audit` | CI |
| Fuzzing | Detective | `make fuzz` | CI (weekly) |

---

## 7. Out of Scope

<!-- TODO(template): attacks the project explicitly does not defend against. Stating these protects
     both users and maintainers. -->
