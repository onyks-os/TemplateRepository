# Governance

## Scale

One maintainer, a handful of contributors. This document is short on purpose: governance that
outruns the project it governs is theatre, and the failure mode of a small project is not a
disputed decision, it is nobody knowing how a decision gets made at all.

See [`MAINTAINERS.md`](MAINTAINERS.md) for who, and for a plain statement of the bus factor.

## How decisions get made

The maintainer decides, in the open, on the issue or pull request. There is no vote, because there is
nobody to vote. What is owed in exchange is a stated reason: a change that is declined gets a
sentence saying why, on the thread, not silence.

Disagreement escalates to the issue tracker, not to private channels. If a decision turns out to be
wrong, reversing it is a normal commit, not an admission requiring ceremony.

## What needs more than one opinion

Some changes are hard to walk back because they propagate. These are held to a higher bar — the
maintainer will seek a second opinion before merging, and will say in the thread that they are doing
so:

- **Anything under `template/*/.github/workflows/`.** These become the CI of every repository
  scaffolded afterwards, with real permissions in repositories the maintainer will never see.
- **`scripts/lib/render.sh`.** Substitution is the one place operator input meets execution.
- **Removing a check from `scripts/openssf-audit.sh` or `tests/run-tests.sh`.** Adding one is cheap;
  removing one silently lowers the floor for every future project.
- **Anything that changes what a *generated* repository's default permissions or triggers are.**

## The standard a change is held to

Not "is this an improvement" but **"is this an improvement for the next twenty repositories, one of
which nobody will re-review."** The template's cost is paid by every project scaffolded from it: a
file that arrives looking finished does not get read again. A change that adds a file to
`template/common/` must be worth the attention of someone who will never open it.

Concretely, that means a change is expected to carry:

- A check in `tests/run-tests.sh` if it fixes a bug, failing without the fix.
- A `TODO(template)` marker only where a human genuinely must write project-specific content — never
  where the template could have written it.
- An entry in [`CHANGELOG.md`](CHANGELOG.md) phrased as what a repository generated after the change
  gets that one generated before it did not.

## Releases

There is no release cadence. `main` is the supported version; see the Supported versions section of
[`SECURITY.md`](SECURITY.md) for why that is the right shape for a scaffolder rather than a gap.

A tag is cut when the changelog's Unreleased section has accumulated something worth pointing at.
Before tagging: `make check`, `make test`, `make check-pins`.

## Changing this document

Same as any other change: a pull request, with the reason in it.
