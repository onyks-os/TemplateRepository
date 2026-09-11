# Static analysis policy

## What runs

| Tool | Over | When |
| :--- | :--- | :--- |
| [ShellCheck](https://www.shellcheck.net/) | `scripts/*.sh`, `scripts/lib/*.sh`, `tests/*.sh` | `make check-shell`, `make test`, every push and pull request |
| [CodeQL](https://codeql.github.com/) | Workflows (`actions`), plus the JavaScript, Python, and Rust sources under `template/` | GitHub's default setup, on every push and pull request |
| `scripts/openssf-audit.sh` | Every workflow under any `.github/workflows/` in the tree, including all four profiles' | `make audit`, and the `audit-self` CI job |

This repository is Bash plus GitHub Actions workflows, so those are the two languages worth
analysing. CodeQL's `actions` pack reads the workflows for injection and privilege mistakes; the
audit checks the same class of defect from a different direction, with rules specific to what this
template ships. The overlap is deliberate — the audit's rules are ours and can be wrong, and CodeQL
is an independent opinion.

CodeQL runs through GitHub's **default setup** rather than a workflow in this repository. The two are
mutually exclusive — an advanced configuration cannot upload its SARIF while default setup is enabled
— and default setup wins here: it already covers `actions` and picks up the JavaScript, Python, and
Rust sources under `template/` as well, with no pinned actions to maintain. A repository *generated*
from this template ships `.github/workflows/codeql.yml` instead, since it cannot know which of the two
its owner will want; that file carries a comment explaining how to resolve the conflict.

ShellCheck runs with `-x`, so sourced libraries are followed rather than skipped.

## Severity and what blocks a merge

**Everything blocks.** ShellCheck runs at its default severity, which includes `info` and `style`,
and CI fails on any finding. There is no triage tier and no accepted-findings list.

This is affordable because the codebase is three scripts, and it is worth it because the alternative —
a backlog of "known" warnings — is where a real finding goes to hide. The test suite asserts
ShellCheck is clean as one of its own checks, so the gate cannot be quietly removed from CI without a
test failing.

## Suppressions

A suppression is a `# shellcheck disable=SCxxxx` comment with a line above it saying why, in terms of
this code rather than in terms of the rule. "False positive" is not a reason; "`compgen -G` needs the
glob unquoted here" is.

Blanket suppressions at file level are not used. `# shellcheck source-path=SCRIPTDIR` and
`# shellcheck source=...` are directives, not suppressions — they tell the tool where to look.

## Handling a finding

1. Fix it. Most ShellCheck findings in this codebase have been real: a `cd` failure masked by
   `readonly`'s exit status, a variable a flag set that nothing read, a file read and rewritten in the
   same pipeline.
2. If it cannot be fixed, suppress it at the narrowest scope with the reason inline.
3. If the rule is wrong for this project in general, say so here rather than suppressing it in twenty
   places.

CodeQL findings appear in the Security tab. A finding in a workflow is treated as a defect in what
this template teaches, not only in this repository, and the fix belongs under `template/` as well
whenever the same shape is shipped there.

## What static analysis does not cover

Everything about the *generated* repository that is not visible in its text. `make test` exists for
that: it scaffolds every profile and audits the result. See
[`DYNAMIC_ANALYSIS_POLICY.md`](DYNAMIC_ANALYSIS_POLICY.md).
