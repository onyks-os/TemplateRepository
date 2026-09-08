/**
 * Property-based tests.
 *
 * Every function that parses or validates untrusted input belongs here. The
 * contract these tests enforce: for any input, the function returns a valid
 * result or throws a documented error — it never crashes with an unexpected
 * error type and never hangs.
 *
 * See DYNAMIC_ANALYSIS_POLICY.md for the triage and remediation process.
 */

import fc from "fast-check";
import { describe, expect, it } from "vitest";

import { run } from "../src/cli.js";

// Pull requests run a small budget; the weekly scheduled workflow raises it.
const numRuns = Number(process.env.FAST_CHECK_RUNS ?? 100);

describe("cli", () => {
  it("never throws on arbitrary arguments", () => {
    fc.assert(
      fc.property(fc.array(fc.string()), (argv) => {
        expect(() => run(argv)).not.toThrow();
      }),
      { numRuns },
    );
  });
});

// TODO(template): add one property per parser and validator reachable from
// untrusted input, and list them in DYNAMIC_ANALYSIS_POLICY.md.
