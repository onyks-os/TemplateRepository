# Contributing to TemplateRepository

This repository is the layer that other repositories are built from. A change here is copied into
every project scaffolded afterwards, so the bar is a little different from a normal project: a defect
does not break this repository, it breaks the next twenty.

## Getting set up

```bash
git clone https://github.com/onyks-os/TemplateRepository
cd TemplateRepository
make check          # shellcheck + profile contract + placeholder binding
make test           # end-to-end: scaffold every profile and audit the result
```

`make test` needs nothing beyond bash, git, and coreutils. Install
[shellcheck](https://www.shellcheck.net/) as well — CI runs it, and without it the suite falls back
to `bash -n`, which catches far less.

## The one rule

**Everything is verified by generating a repository, not by reading the template.** The template is
input; the generated repository is the product. `tests/run-tests.sh` scaffolds all four profiles into
a temporary directory and asserts on what came out — that nothing is left unrendered, that the audit
reports zero missing criteria, that a replay of `answers.env` is byte-identical. Add your check there,
in those terms.

## How the pieces fit

| Path | What it is |
| :--- | :--- |
| `scripts/bootstrap.sh` | Renders `template/` into a target directory. Never overwrites without `--force`. |
| `scripts/openssf-audit.sh` | Reads any repository, reports OpenSSF readiness and workflow safety. |
| `scripts/pin-actions.sh` | Refreshes the action SHA pins inside `template/`. |
| `scripts/lib/render.sh` | Placeholder substitution. Bash parameter expansion over a fixed key list. |
| `template/common/` | Everything language-agnostic. Copied for every profile. |
| `template/<lang>/` | One language profile. Must implement the full `lang-*` contract. |
| `tests/run-tests.sh` | The suite. Runs against generated output. |

`docs/interfaces.md` is the reference for every command-line flag and every Make target.

## Making a change

### Adding or editing a template file

Add it under `template/common/` if it is language-agnostic, `template/<profile>/` otherwise. Then:

1. **Every `{{PLACEHOLDER}}` you use must be bound.** `make check-placeholders` lists what the
   template references and fails on anything `bootstrap.sh` and the `profile.env` files do not assign.
   `docs/placeholders.md` documents each one.
2. **Leave `TODO(template)` where a human must write project-specific content.** That is how
   `make todo` finds it in a generated repository, and how the audit reports remaining debt. Do not
   leave a marker where you could have written the content.
3. **Run `make test`.** A new file that fails to render is caught there, not in review.

### Adding a language profile

`docs/profiles.md` is the walkthrough. The short version: copy `template/generic/`, implement all
nine `lang-*` targets in `make/<profile>.mk`, and fill in `profile.env`. `make check-profiles`
enforces the contract, and the test suite picks the profile up once it is listed in `PROFILES` in
`tests/run-tests.sh`.

### Changing a workflow under `template/`

Read the **Security Best Practices for GitHub Actions** section of
[`template/common/CONTRIBUTING.md`](template/common/CONTRIBUTING.md) first — that is the document
your change will be teaching to every generated repository, and the rules in it apply here too. In
particular:

- **Never combine `pull_request_target` with a checkout of the pull request.** The test suite asserts
  no shipped workflow uses the trigger at all.
- **Pin every action to a commit SHA**, with the version in a trailing comment:
  `uses: actions/checkout@11d5960a... # v4.4.0`. The test suite fails on an unpinned action.
- **Pass untrusted values through `env:`**, never interpolate them into a `run:` block.

`scripts/openssf-audit.sh` checks all three, and `tests/fixtures/` holds a deliberately dangerous
workflow plus its safe counterpart so the checks themselves are tested. Do not "fix" the dangerous
fixture — the suite asserts it stays broken.

### Refreshing the action pins

Dependabot maintains the pins in this repository's own `.github/workflows/`, but it does not see the
copies under `template/` — they are inert YAML there, not workflows this repository runs. Refresh
them by hand:

```bash
scripts/pin-actions.sh --check      # report what is stale
scripts/pin-actions.sh --verify     # assert every pin names a commit that exists
scripts/pin-actions.sh              # rewrite, staying within the current major
scripts/pin-actions.sh --allow-major
make test
```

Run `--verify` after editing a pin by hand. A 40-hex string looks like a pin whether or not it names
a real commit, and a typo surfaces only when the workflow runs — which for a release workflow means
at the worst possible moment.

It needs an authenticated `gh`. Read the diff before committing: an action that changed major version
may need its inputs adjusted.

## Commit and pull request

Commits are signed off — this repository uses the
[Developer Certificate of Origin](https://developercertificate.org/), the same policy it scaffolds
into every project it generates:

```bash
git commit -s -m "fix(template): describe what changed"
```

Use [Conventional Commits](https://www.conventionalcommits.org/). The scopes in use are `template`
(files under `template/`), `scripts`, `docs`, `tests`, and `ci`.

Before pushing:

```bash
make check && make test
```

In the pull request, say which profiles you exercised and paste the summary line of `make test`. If
you changed anything under `template/`, say what a repository generated after your change gets that it
did not get before.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Reports go through
[GitHub private vulnerability reporting](https://github.com/onyks-os/TemplateRepository/security/advisories)
or a direct message to the maintainer.
