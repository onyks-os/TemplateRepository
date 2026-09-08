# Secrets Management Policy

## Principles

1. **No secrets are hardcoded** in the source code, tests, fixtures, or documentation.
2. Tokens and service keys (signing keys, registry credentials) are stored exclusively as
   **GitHub Actions secrets** or local environment variables.
3. Release signing keys live only on the maintainer's machine or in a keyless OIDC flow
   (Sigstore), and are never committed.
4. `.env` files are git-ignored; only `.env.example`, containing placeholder values, is committed.

## Detection

- Secret scanning and push protection are enabled on the GitHub repository.
- `make lint` fails if a tracked file matches the project's secret patterns.

## Incident Response

If a secret is accidentally committed:

1. **Revoke and rotate the credential immediately** — treat it as compromised the moment it is pushed.
2. Remove it from the history (`git filter-repo`) and force-push, coordinating with contributors.
3. Record the incident in [`CHANGELOG.md`](CHANGELOG.md) under a `### Security` subsection.
