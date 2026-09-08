# SAST Policy

{{PROJECT_SHORT}} uses **CodeQL** (GitHub) and the project linter for static analysis (SAST) of the
codebase. Both run on every pull request targeting `main`.

## Severity Thresholds

- **Critical / High**: must be resolved **before merging** the pull request.
- **Medium**: resolved within **7 days** of identification.
- **Low**: acceptable for merging, but should be resolved in the next release.

## Remediation Process

1. The pull request is blocked if CodeQL detects Critical/High findings.
2. The developer fixes the code, or marks the alert as a false positive using the appropriate
   inline suppression comment.
3. Once corrected, the status check passes and the pull request can be merged.

## False Positives

If a finding is deemed non-exploitable or a false positive, it must be suppressed inline with a
comment explaining the rationale. Blanket suppressions at file or project level are not accepted.

## Tooling

| Tool           | Scope                          | Where it runs                          |
| :------------- | :----------------------------- | :------------------------------------- |
| CodeQL         | Semantic dataflow analysis     | `.github/workflows/codeql.yml`         |
| {{LINTER_NAME}}    | Style, bug patterns, complexity | `make lint`, `.github/workflows/ci.yml` |
| ShellCheck     | Shell scripts under `scripts/` | `make lint`, `.github/workflows/ci.yml` |
