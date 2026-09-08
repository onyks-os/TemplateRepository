//! Property-based tests.
//!
//! Every function that parses or validates untrusted input belongs here. The
//! contract: for any input, the function returns a valid result or a documented
//! error — it never panics and never hangs.
//!
//! See `DYNAMIC_ANALYSIS_POLICY.md` for the triage and remediation process.

use proptest::prelude::*;

proptest! {
    #[test]
    fn version_is_stable(_noise in ".*") {
        prop_assert!(!{{CRATE_NAME}}::VERSION.is_empty());
    }
}

// TODO(template): add one property per parser and validator reachable from
// untrusted input, and list them in `DYNAMIC_ANALYSIS_POLICY.md`.
