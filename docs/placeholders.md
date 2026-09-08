# Placeholders

Every `{{VARIABLE}}` the template uses, where its value comes from, and what it renders into.
`make check-placeholders` fails if any placeholder in `template/` is not bound by
`scripts/bootstrap.sh` or by a profile's `profile.env`.

Substitution replaces only the keys listed here. GitHub Actions expressions such as
`${{ github.ref }}` share the brace syntax but are never touched, because they do not match a
registered key.

## Asked for

| Placeholder | Prompt | Default | Example |
| :---------- | :----- | :------ | :------ |
| `PROJECT_SLUG` | Repository name | Target directory name | `TransparentTorProxy` |
| `PROJECT_NAME` | Human-readable name | `PROJECT_SLUG` | `Transparent Tor Proxy` |
| `PROJECT_SHORT` | Short name / acronym | Capitals of `PROJECT_NAME` | `TTP` |
| `PROJECT_DESC` | One-line description | `TODO: describe …` | `Routes all system traffic through Tor` |
| `PROJECT_PKG` | Package / module name | Slug of `PROJECT_SHORT` | `ttp` |
| `PROJECT_DIST` | Distribution name | Slug of `PROJECT_SLUG` | `transparent-tor-proxy` |
| `GITHUB_OWNER` | GitHub owner | `git config user.github` | `onyks-os` |
| `AUTHOR_NAME` | Author name | `git config user.name` | `onyks` |
| `CONTACT_EMAIL` | Contact email | `git config user.email` | `you@example.com` |
| `SECURITY_EMAIL` | Security reporting email | `CONTACT_EMAIL` | `sec@example.com` |
| `LICENSE_ID` | SPDX identifier | `MIT` | `Apache-2.0` |
| `VERSION` | Initial version | `0.1.0` | `0.4.7` |
| `DOCS_SLUG` | Documentation path segment | Slug of `PROJECT_SHORT` | `ttp` |
| `OPENSSF_PROJECT_ID` | Best Practices project ID | `0` | `13164` |

## Derived

| Placeholder | Derived from | Example |
| :---------- | :----------- | :------ |
| `COPYRIGHT_YEAR` | Current year | `2026` |
| `DATE` | Today, ISO 8601 | `2026-09-03` |
| `DOCS_URL` | `GITHUB_OWNER` + `DOCS_SLUG` | `https://onyks-os.github.io/ttp/` |
| `DOCS_SITE_DIR` | MkDocs output, matching the GitHub Pages repo layout | `../onyks-os.github.io/ttp` |
| `PROJECT_ENV_PREFIX` | `PROJECT_SHORT`, upper-cased | `TTP` |
| `PY_TARGET` | `MIN_LANG_VERSION` without dots — Ruff's `target-version` | `310` |
| `CRATE_NAME` | `PROJECT_DIST` with `-` → `_` — Rust resolves library crates this way | `transparent_tor_proxy` |
| `LANG_PROFILE` | `--profile` | `python` |

## From the profile

Each `template/<profile>/profile.env` supplies these, and any of them can still be overridden with
`--set`:

| Placeholder | Purpose | `python` | `node` | `rust` |
| :---------- | :------ | :------- | :----- | :----- |
| `PRIMARY_LANGUAGE` | README badge, docs prose | `Python` | `TypeScript` | `Rust` |
| `PRIMARY_LANGUAGE_LOGO` | Shields.io logo slug | `python` | `typescript` | `rust` |
| `MIN_LANG_VERSION` | Minimum supported version | `3.10` | `20` | `1.75` |
| `CODEQL_LANGUAGE` | CodeQL matrix entry | `python` | `javascript-typescript` | `rust` |
| `DEPENDABOT_ECOSYSTEM` | `dependabot.yml` ecosystem | `pip` | `npm` | `cargo` |
| `LINTER_NAME` | Named in `SAST_POLICY.md` | `Ruff` | `ESLint` | `Clippy` |

## Adding a placeholder

1. Use `{{NEW_KEY}}` in the template file.
2. Bind it in `scripts/bootstrap.sh` — an `ask NEW_KEY …` line for a prompted value, or a
   `VARS[NEW_KEY]=…` line for a derived one — or in a profile's `profile.env`.
3. Run `make check-placeholders`; it fails on anything unbound.
4. Document it in the table above.
