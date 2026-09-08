# Dynamic Analysis Policy

{{PROJECT_SHORT}} uses property-based testing and fuzzing to exercise parsing and validation code
paths with generated inputs.

## Scope

The fuzzer exercises the following attack surfaces:

<!-- TODO(template): list every parser, deserializer, regex, and validation routine reachable from
     untrusted input. These are the functions the fuzzer must target. -->

- `<!-- TODO(template): module.function -->`

## Process for Vulnerabilities Found by the Fuzzer

1. **Triage**: a crash or logic error found by the fuzzer is assigned `P1` (Critical) priority in the
   issue tracker.
2. **Remediation**: a fix **must** be merged within **7 days** of confirmation.
3. **Verification**: after the fix, the fuzzer **must** run successfully on the updated codebase with
   a high example count (for example `max_examples=10000`) to confirm the issue is resolved. The
   failing input is added to the regression corpus.
4. **Documentation**: every confirmed vulnerability gets an entry in [`CHANGELOG.md`](CHANGELOG.md)
   under a `### Security` subsection, describing the issue and the fix.

## Assertions

Assertions are enabled during all test and fuzzing runs. Optimization flags that strip assertions are
**never** used in CI.

## Automation

The fuzzing workflow (`.github/workflows/fuzzing.yml`) runs automatically:

- On every pull request targeting `main`.
- Weekly, every Sunday at midnight UTC, via scheduled cron.
