# Repository Modification & Documentation Policy

This document defines the requirements for keeping the source code, the test suites, and the project
documentation consistent. It specifies exactly which files must be updated for every type of
modification to the repository.

---

## Modification Matrix Summary

| Type of Modification            | Tests Required? | `CHANGELOG.md` | `docs/interfaces.md` | `docs/architecture.md` | `README.md` | `docs/security-assessment.md` | `DEPENDENCIES.md` |
| :------------------------------ | :-------------: | :------------: | :------------------: | :--------------------: | :---------: | :---------------------------: | :---------------: |
| **1. Public API / CLI surface** |      ✅ Yes      |     ✅ Yes      |        ✅ Yes         |        ⚠️ Maybe         |   ⚠️ Maybe   |         ✅ Yes (STRIDE)        |       ❌ No        |
| **2. Core logic**               |      ✅ Yes      |     ✅ Yes      |        ❌ No          |        ✅ Yes           |   ❌ No      |         ✅ Yes                 |       ❌ No        |
| **3. Dependencies / versions**  |      ❌ No       |     ✅ Yes      |        ❌ No          |        ❌ No            |   ❌ No      |         ✅ Yes (supply chain)  |       ✅ Yes       |
| **4. Packaging / installers**   |      ❌ No       |     ✅ Yes      |        ❌ No          |        ❌ No            |   ⚠️ Maybe   |         ❌ No                  |   ✅ Yes (sys deps) |
| **5. Test suite / fuzzing**     |      ❌ No       |     ✅ Yes      |        ❌ No          |        ❌ No            |   ❌ No      |         ❌ No                  |       ❌ No        |
| **6. Security policies**        |      ❌ No       |     ✅ Yes      |        ❌ No          |        ❌ No            |   ❌ No      |         ❌ No                  |       ❌ No        |
| **7. Architectural decisions**  |      ❌ No       |     ✅ Yes      |       ⚠️ Maybe        |        ✅ Yes           |   ⚠️ Maybe   |         ✅ Yes                 |       ❌ No        |
| **8. Pure documentation**       |      ❌ No       |     ✅ Yes      |        ❌ No          |        ❌ No            |   ❌ No      |         ❌ No                  |       ❌ No        |

---

## Detailed Requirements by Scenario

### 1. Modifying the Public API or CLI Surface

When adding, changing, or removing commands, options, flags, exported functions, or default values:

* **Tests**: add or update interface-level tests covering argument parsing and validation.
* **`CHANGELOG.md`**: add an entry under `### Added`, `### Changed`, or `### Removed`.
* **`docs/interfaces.md`**: update the interface tables, including options, required privileges, and
  exit codes.
* **`docs/security-assessment.md`**: re-verify the STRIDE analysis for the input boundary; new user
  input is a new sanitization boundary.
* **`README.md`**: update only if the change affects the Quick Start or is a major user-facing feature.

### 2. Modifying Core Logic

* **Tests**: add unit tests in the corresponding test module; run the integration suite if the change
  crosses a system boundary.
* **`CHANGELOG.md`**: describe the change under `### Added`, `### Changed`, or `### Fixed`.
* **`docs/architecture.md`**: update the component description and diagrams if interactions changed.
* **`docs/security-assessment.md`**: re-evaluate the threat model; document new boundaries and controls.

### 3. Adding or Updating Dependencies

* **`CHANGELOG.md`**: log the addition or version bump.
* **`DEPENDENCIES.md`**: update the dependency table with version constraint, license, purpose, and
  security justification.
* **`docs/security-assessment.md`**: update the supply-chain controls section.

### 4. Modifying Packaging or Installers

* **`CHANGELOG.md`**: detail the change under `### Changed` or `### Added`.
* **`DEPENDENCIES.md`**: update the system-level dependency section if requirements changed.
* **`README.md`**: update the Installation section if paths, requirements, or options changed.

### 5. Modifying or Adding Tests

* **`CHANGELOG.md`**: document under `### Changed` or `### Fixed` when the change affects coverage,
  flakiness, or CI execution.
* **Other docs**: none, unless the test harness itself becomes a user-facing tool.

### 6. Updating Security Policies

* **`CHANGELOG.md`**: add a brief entry.
* **Other docs**: none.

### 7. Architectural Decisions (ADR)

* **ADR document**: create `docs/decisions/XXXX-brief-description.md` from
  [`0000-adr-template.md`](decisions/0000-adr-template.md), and register it in the index in
  [`docs/decisions/README.md`](decisions/README.md). Use `make adr TITLE="..."` to scaffold it.
* **`CHANGELOG.md`**: log the decision and the features stemming from it.
* **`docs/architecture.md`**: document the component changes and update the diagrams.
* **`docs/interfaces.md`**: update if the decision changes the public interface or config schema.
* **`docs/security-assessment.md`**: re-run the threat analysis for the new design.

### 8. Pure Documentation Changes

* **`CHANGELOG.md`**: document the update.
* **Other files**: none.

---

## Commit & PR Checklist for Contributors

Before submitting any pull request:

1. [ ] **Code**: the feature or fix is fully implemented.
2. [ ] **Tests**: coverage is maintained or increased; `make test` passes locally.
3. [ ] **Quality**: `make lint` passes.
4. [ ] **Documentation**:
   * [ ] `CHANGELOG.md` updated under `[Unreleased]`.
   * [ ] The `docs/` files required by the matrix above are updated.
5. [ ] **DCO sign-off**: all commits are signed off (`git commit -s`).
