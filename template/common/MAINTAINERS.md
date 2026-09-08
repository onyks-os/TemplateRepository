# Maintainers

This document lists the maintainers of {{PROJECT_NAME}} ({{PROJECT_SHORT}}) and defines the processes
governing maintainership responsibilities, access, and lifecycle.

---

## Project Lead

| Handle       | GitHub                                             | Role                     | Since        |
| :----------- | :------------------------------------------------- | :----------------------- | :----------- |
| `{{AUTHOR_NAME}}` | [@{{GITHUB_OWNER}}](https://github.com/{{GITHUB_OWNER}}) | Creator & Lead Developer | {{COPYRIGHT_YEAR}} |

## Core Contributors

*We are actively looking for contributors who want to take on a maintainer role. See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to get involved.*

## Emeritus Maintainers

*Maintainers who have stepped down but made significant past contributions are listed here with our
gratitude.*

---

## Project Roles

The table maps each operational role to its current holder. One person may hold multiple roles, as is
the case for a solo-maintained project.

| Role                 | Current Holder | Responsibilities                                                                                     |
| :------------------- | :------------- | :--------------------------------------------------------------------------------------------------- |
| **Project Lead**     | `{{AUTHOR_NAME}}`  | Final decision-maker on architecture, roadmap, and breaking changes.                                 |
| **Code Reviewer**    | `{{AUTHOR_NAME}}`  | Reviews and approves pull requests; enforces coding standards and architectural principles.          |
| **Release Manager**  | `{{AUTHOR_NAME}}`  | Owns the release pipeline: version bump, changelog, artifact build, publication, and signing.        |
| **Security Officer** | `{{AUTHOR_NAME}}`  | Triages private disclosures, coordinates fixes, publishes advisories, keeps `SECURITY.md` current.   |
| **CI/CD Maintainer** | `{{AUTHOR_NAME}}`  | Maintains GitHub Actions workflows, manages repository secrets, keeps the pipeline healthy.          |

> As the project gains contributors, roles will be distributed and this table updated accordingly.

---

## Access to Sensitive Resources

| Resource                   | Access Holder | Notes                                                    |
| :------------------------- | :------------ | :------------------------------------------------------- |
| GitHub Repository (Admin)  | `{{AUTHOR_NAME}}` | Full admin access                                        |
| Package Registry           | `{{AUTHOR_NAME}}` | Owner of the published package                           |
| GitHub Actions Secrets     | `{{AUTHOR_NAME}}` | Manages CI/CD credentials                                |
| Release Signing            | `{{AUTHOR_NAME}}` | Signs release artifacts (Sigstore keyless / GPG)         |
| Security Reporting Inbox   | `{{AUTHOR_NAME}}` | `{{SECURITY_EMAIL}}` — see [SECURITY.md](SECURITY.md)        |

---

## Responsibilities

Maintainers are expected to:

- **Review and merge pull requests** in a timely manner (target: within 7 days).
- **Triage issues**: label, respond to, and close stale issues.
- **Enforce the security policies** defined in [SECURITY.md](SECURITY.md).
- **Ensure CI passes** (`make verify`) before merging any change.
- **Manage releases**: version bump, changelog, artifact build, and publication.
- **Respond to security disclosures** within 48 hours.

---

## Merge Policy

- All changes to `main` go through a pull request. Direct pushes are reserved for critical hotfixes.
- At least **one maintainer approval** is required before merging.
- All CI checks must pass.
- Pull requests touching security-critical paths require explicit sign-off from the Project Lead.
  <!-- TODO(template): list the security-critical paths for this project. -->

---

## Becoming a Maintainer

Maintainership is granted based on sustained, high-quality contributions:

1. Contribute multiple non-trivial pull requests that are reviewed and merged.
2. Demonstrate understanding of the architecture and security model.
3. Be nominated by the Project Lead or an existing Core Contributor.
4. Accept the [Code of Conduct](CODE_OF_CONDUCT.md) and the responsibilities described here.

---

## Offboarding a Maintainer

When a maintainer becomes inactive or steps down:

1. They are moved to the **Emeritus** section of this file.
2. All access (GitHub admin, registry, secrets) is revoked promptly.
3. Any release signing keys or credentials they held are rotated.
4. A note is added to the changelog if they made significant contributions.

---

## Bus Factor

This project currently has a bus factor of **1**. All credentials required to continue the project
are documented above. In the event the Project Lead becomes unreachable for more than 90 days,
maintainership may be claimed by a Core Contributor by opening a public issue and, absent objection
within 30 days, requesting a repository transfer through GitHub Support.
