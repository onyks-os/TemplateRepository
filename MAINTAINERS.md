# Maintainers

| Name | GitHub | Role |
| :--- | :--- | :--- |
| Project lead | [@onyks-os](https://github.com/onyks-os) | Everything |

## Bus factor

**One.** This is stated plainly rather than left for someone to discover, because it is the honest
answer to the OpenSSF gold criterion `bus_factor >= 2` and because it changes how you should treat
this repository: if you scaffold from it, you are taking a copy of files you can maintain yourself,
not a dependency on a maintained service. That is the intended relationship — a generated repository
keeps working whether or not this one does.

Reducing it to zero risk is not possible with one person. What is possible, and is done:

- Everything the maintainer knows about verifying a change is in `make check` and `make test`, not in
  their head. A stranger can tell whether a change is good.
- The scaffolder fetches nothing at scaffold time, so a generated repository does not depend on this
  one being reachable.
- `LICENSE` is MIT. A fork needs no permission.

## Responsibilities

- **Review.** Every change is reviewed before merge, including the maintainer's own where a second
  pair of eyes is available. `CODEOWNERS` routes `scripts/`, both `.github/workflows/` trees, and
  `SECURITY.md` explicitly, because a change there is inherited by every repository scaffolded
  afterwards.
- **Security reports.** Acknowledged within 48 hours, per [`SECURITY.md`](SECURITY.md).
- **Pins.** `make check-pins` is run before each release; `make pin-actions` applies the updates.
  Dependabot cannot do this — it does not traverse `template/`.

## Becoming a maintainer

There is no formal process yet, which is another way of saying the bus factor has not been addressed.
The practical route is the usual one: a few merged pull requests, then ask. Sustained review of other
people's changes counts for more than volume of code.
