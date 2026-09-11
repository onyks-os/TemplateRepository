## What changed

<!-- One paragraph. If this touches template/, say what a repository generated after this change
     gets that it did not get before. -->

## Why

<!-- The situation that made this necessary. -->

## Verification

```
<!-- Paste the summary line of `make test`. -->
```

- [ ] `make check` passes
- [ ] `make test` passes
- [ ] Commits are signed off (`git commit -s`)

<!-- If you changed anything under template/ -->
- [ ] Every new `{{PLACEHOLDER}}` is bound (`make check-placeholders`)
- [ ] `TODO(template)` is left only where a human must write project-specific content
- [ ] Profiles exercised: <!-- python / node / rust / generic -->

<!-- If you changed a workflow under template/ -->
- [ ] Every action is pinned to a commit SHA with the version in a trailing comment
- [ ] No `pull_request_target`
- [ ] Untrusted values reach `run:` through `env:`, never by interpolation
