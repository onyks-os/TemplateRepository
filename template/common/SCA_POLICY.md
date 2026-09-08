# Software Composition Analysis (SCA) Policy

{{PROJECT_SHORT}} uses **Dependabot** to monitor vulnerabilities in its dependencies, plus
`make audit` for on-demand local scanning.

## Severity Thresholds

- **Critical / High**: must be resolved within **7 days** of notification.
- **Medium**: resolved within **30 days**.
- **Low**: resolved in the next release, or accepted with a documented justification.

## Remediation Process

1. Dependabot automatically opens a pull request with the update.
2. The pull request is merged once CI passes.
3. If the update is not possible (for example a breaking change), we evaluate a backported patch or
   isolation of the dependency, and document the accepted risk in
   [`docs/security-assessment.md`](docs/security-assessment.md).

## License Compliance

Dependencies must carry a license compatible with the project license ({{LICENSE_ID}}). Any conflict
must be resolved before merging. Every direct dependency is recorded in
[`DEPENDENCIES.md`](DEPENDENCIES.md) with its license.

## Before Each Release

- Run `make audit` and verify there are no unresolved vulnerabilities.
- Review outstanding Dependabot alerts manually.
- If unresolved Critical or High vulnerabilities remain, **the release is blocked** until remediation.
