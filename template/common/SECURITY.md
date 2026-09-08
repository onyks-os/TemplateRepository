# Security Policy

## Reporting a Vulnerability

We take the security of {{PROJECT_SHORT}} seriously. If you discover a security vulnerability in this
project, please **do not open a public issue**.

### How to report (preferred method)

Use GitHub's **private vulnerability reporting**:

1. Go to [https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/security/advisories](https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/security/advisories)
2. Click **"Report a vulnerability"**
3. Fill out the form with as much detail as possible:
   - Description of the issue
   - Steps to reproduce
   - Affected versions
   - Potential impact

### Alternative contact

If you cannot use GitHub's private reporting, email the maintainers at `{{SECURITY_EMAIL}}`.

Email may have a lower response priority than GitHub advisories.

## What to expect

- You will receive an acknowledgment within **48 hours**.
- We will investigate and keep you informed of progress at least every **7 days**.
- Once a fix is ready, we will credit you in the release notes (unless you prefer to remain anonymous).

## Public Disclosure

When a vulnerability is confirmed and fixed, {{PROJECT_SHORT}} publishes a public advisory containing:

- Affected versions
- Description of the issue
- Mitigation or upgrade instructions

The advisory is published on:

- **GitHub Security Advisories** — `https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/security/advisories`
- **Release notes** of the fixed version

We do not currently assign CVEs, but may do so in the future.

## Scope

This policy applies to the {{PROJECT_SHORT}} core modules and its public interfaces.

The following are considered **critical scope targets**:

<!-- TODO(template): list the concrete attack outcomes that qualify as critical for THIS project.
     Be specific: "bypassing X to reach Y", not "any security issue". -->

1. **<!-- TODO(template): critical target 1 -->**
2. **<!-- TODO(template): critical target 2 -->**

Out of scope:

- Vulnerabilities in third-party dependencies already tracked upstream (report them upstream, then
  open an issue here referencing the advisory).
- Findings that require an already-compromised host or physical access.

For the full STRIDE threat model, trust boundaries, risk severity ratings, and security controls
inventory, see **[`docs/security-assessment.md`](docs/security-assessment.md)**.

## Informal Bug Bounty & Hall of Fame

There is no financial budget for monetary rewards, but the project recognizes researchers who help
make {{PROJECT_SHORT}} safer. For valid, in-scope reports that are confirmed and resolved:

- **Permanent inclusion** in [`HALL_OF_FAME.md`](HALL_OF_FAME.md), with a link to the researcher's
  GitHub profile or personal website.
- **Honorable mention** in the GitHub Release Notes of the fixed version.

## Release support policy

| Version   | Support status      | End of life                    |
| --------- | ------------------- | ------------------------------ |
| {{VERSION}}   | ✅ Security fixes   | When the next minor is released |
| < {{VERSION}} | ❌ Unsupported      |                                |

- Security fixes are provided only for the latest minor version.
- If you need long-term support, contact the maintainers.

## Security Hardening of the Project Itself

- All dependencies are monitored by Dependabot; see [`SCA_POLICY.md`](SCA_POLICY.md).
- Static analysis runs on every pull request; see [`SAST_POLICY.md`](SAST_POLICY.md).
- Secrets are never committed; see [`SECRETS_POLICY.md`](SECRETS_POLICY.md).
- Release artifacts are signed and reproducible; see [`docs/verification.md`](docs/verification.md).

## Acknowledgments

We thank the community for responsibly disclosing security issues. Contributors who report valid
vulnerabilities are publicly acknowledged unless they request otherwise.
