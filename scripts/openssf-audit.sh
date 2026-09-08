#!/usr/bin/env bash
#
# openssf-audit.sh — report how close a repository is to the OpenSSF Best
# Practices badge, and what is still missing.
#
#   scripts/openssf-audit.sh [path-to-repo] [--level passing|silver|gold] [--quiet]
#
# Checks that a script can decide are answered automatically. Criteria that
# require human judgement (bus factor, coverage percentage, cryptographic
# choices) are reported as MANUAL so they are not silently assumed to pass.
#
# Reference: https://www.bestpractices.dev/en/criteria

set -euo pipefail

REPO="${1:-.}"
[[ "$REPO" == --* ]] && REPO="."
LEVEL="all"
QUIET=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --level) LEVEL="${2:?}"; shift 2 ;;
        --quiet) QUIET=1; shift ;;
        -h|--help)
            sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) shift ;;
    esac
done

[[ -d "$REPO" ]] || { echo "Not a directory: $REPO" >&2; exit 1; }
REPO="$(cd "$REPO" && pwd)"

readonly C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_RED=$'\033[31m' C_GREEN=$'\033[32m'
readonly C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m' C_OFF=$'\033[0m'

declare -i PASS=0 FAIL=0 MANUAL=0
declare -a REMEDIATION=()

section() { printf '\n%s%s%s\n%s\n' "${C_BOLD}" "$1" "${C_OFF}" "$(printf '%.0s-' $(seq 1 ${#1}))"; }

# ok <criterion> <detail>
ok()   { (( PASS += 1 )); (( QUIET )) || printf '  %s✔%s %-46s %s%s%s\n' "${C_GREEN}" "${C_OFF}" "$1" "${C_DIM}" "${2:-}" "${C_OFF}"; }
no()   { (( FAIL += 1 )); printf '  %s✘%s %-46s %s%s%s\n' "${C_RED}" "${C_OFF}" "$1" "${C_DIM}" "${2:-}" "${C_OFF}"; REMEDIATION+=("$1 — ${2:-}"); }
man()  { (( MANUAL += 1 )); (( QUIET )) || printf '  %s?%s %-46s %s%s%s\n' "${C_YELLOW}" "${C_OFF}" "$1" "${C_DIM}" "${2:-}" "${C_OFF}"; }

# have <criterion> <path> [hint]
have() {
    local name="$1" path="$2" hint="${3:-add ${2}}"
    if [[ -e "${REPO}/${path}" ]]; then ok "$name" "$path"; else no "$name" "$hint"; fi
}

# have_any <criterion> <hint> <path>...
have_any() {
    local name="$1" hint="$2"; shift 2
    local p
    for p in "$@"; do
        [[ -e "${REPO}/${p}" ]] && { ok "$name" "$p"; return 0; }
    done
    no "$name" "$hint"
}

# contains <criterion> <file> <regex> <hint>
contains() {
    local name="$1" file="$2" pattern="$3" hint="$4"
    if [[ -f "${REPO}/${file}" ]] && grep -qiE "$pattern" "${REPO}/${file}"; then
        ok "$name" "$file"
    else
        no "$name" "$hint"
    fi
}

# glob_any <criterion> <hint> <glob>
glob_any() {
    local name="$1" hint="$2" pattern="$3"
    # shellcheck disable=SC2086
    if compgen -G "${REPO}/${pattern}" > /dev/null; then ok "$name" "$pattern"; else no "$name" "$hint"; fi
}

printf '%s%s%s\n' "${C_BOLD}" "OpenSSF Best Practices readiness — $(basename "$REPO")" "${C_OFF}"
printf '%s%s%s\n' "${C_DIM}" "$REPO" "${C_OFF}"

# =========================================================================
if [[ "$LEVEL" == "all" || "$LEVEL" == "passing" ]]; then
section "PASSING — Basics & documentation"
have     "description_good (README)"            "README.md"
have_any "contribution (CONTRIBUTING)"          "add CONTRIBUTING.md"            "CONTRIBUTING.md" ".github/CONTRIBUTING.md"
have_any "license_location (LICENSE)"           "add a LICENSE file"             "LICENSE" "LICENSE.md" "LICENSE.txt"
have     "documentation_basics (docs/)"         "docs"
have     "documentation_interface"              "docs/interfaces.md"
contains "sites_https (README uses HTTPS)"      "README.md" "https://"           "link the project homepage over HTTPS"

section "PASSING — Reporting"
have_any "report_process (SECURITY policy)"     "add SECURITY.md"                "SECURITY.md" ".github/SECURITY.md"
have_any "report_tracker (issue templates)"     "add .github/ISSUE_TEMPLATE/"    ".github/ISSUE_TEMPLATE" ".github/ISSUE_TEMPLATE.md"
contains "vulnerability_report_private"         "SECURITY.md" "private|advisor|security/advisories" \
                                                "document a private reporting channel in SECURITY.md"
contains "vulnerability_report_response"        "SECURITY.md" "48 hours|within .* (hours|days)" \
                                                "state a response time commitment in SECURITY.md"

section "PASSING — Change control & release"
have     "version_unique (CHANGELOG)"           "CHANGELOG.md"
contains "version_semver"                       "CHANGELOG.md" "semver|semantic versioning" \
                                                "declare Semantic Versioning in CHANGELOG.md"
contains "release_notes"                        "CHANGELOG.md" "keep a changelog" \
                                                "follow Keep a Changelog in CHANGELOG.md"
glob_any "repo_distributed (git repository)"    "run git init"                   ".git"

section "PASSING — Quality"
have_any "build (reproducible entrypoint)"      "add a Makefile"                 "Makefile" "make"
have     "test (automated test suite)"          "tests"
glob_any "automated_integration_testing (CI)"   "add .github/workflows/ci.yml"   ".github/workflows/ci.yml"
contains "test_policy (tests required)"         "CONTRIBUTING.md" "test" \
                                                "state the test policy for new functionality in CONTRIBUTING.md"
contains "warnings (linting enforced)"          "Makefile" "lint" \
                                                "add a lint target to the Makefile"

section "PASSING — Security"
contains "know_secure_design (threat model)"    "docs/security-assessment.md" "stride|threat" \
                                                "write the STRIDE analysis in docs/security-assessment.md"
glob_any "static_analysis (CodeQL)"             "add .github/workflows/codeql.yml" ".github/workflows/codeql.yml"
have     "static_analysis_common_vulnerabilities" "SAST_POLICY.md"
have     "dynamic_analysis"                     "DYNAMIC_ANALYSIS_POLICY.md"
have     "dependency_monitoring"                ".github/dependabot.yml"
man      "crypto_* (cryptographic practice)"    "answer on bestpractices.dev if the project uses cryptography"
man      "vulnerabilities_fixed_60_days"        "track open advisories yourself"
fi

# =========================================================================
if [[ "$LEVEL" == "all" || "$LEVEL" == "silver" ]]; then
section "SILVER — Governance"
have     "governance"                           "GOVERNANCE.md"
have     "roles_responsibilities"               "MAINTAINERS.md"
have     "code_of_conduct"                      "CODE_OF_CONDUCT.md"
have     "access_continuity (CODEOWNERS)"       ".github/CODEOWNERS"
contains "contribution_requirements (DCO)"      "CONTRIBUTING.md" "signed-off-by|dco|developer certificate" \
                                                "document the DCO sign-off requirement in CONTRIBUTING.md"
glob_any "dco_enforced"                         "add .github/workflows/dco.yml" ".github/workflows/dco.yml"

section "SILVER — Documentation"
have     "documentation_architecture"           "docs/architecture.md"
have     "documentation_security"               "docs/security-assessment.md"
have     "documentation_quick_start"            "docs/web/tutorials/quickstart.md"
have     "documentation_roadmap"                "ROADMAP.md"
have     "documentation_achievements (ADRs)"    "docs/decisions"
have     "installation_development_quick"       "mkdocs.yml"

section "SILVER — Supply chain & release integrity"
glob_any "signed_releases"                      "add .github/workflows/release.yml" ".github/workflows/release.yml"
contains "signed_releases (cryptographic)"      ".github/workflows/release.yml" "sigstore|gpg|cosign" \
                                                "sign release artifacts (Sigstore) in release.yml"
contains "sbom (bill of materials)"             ".github/workflows/release.yml" "sbom|cyclonedx|cdxgen" \
                                                "generate an SBOM in release.yml"
have     "dependency_policy"                    "DEPENDENCIES.md"
have     "secrets_policy"                       "SECRETS_POLICY.md"
have     "sca_policy"                           "SCA_POLICY.md"
glob_any "scorecard (OpenSSF Scorecard)"        "add .github/workflows/scorecard.yml" ".github/workflows/scorecard.yml"
glob_any "dependency_review"                    "add .github/workflows/dependency-review.yml" ".github/workflows/dependency-review.yml"
have     "release_verification_guide"           "docs/verification.md"

section "SILVER — Testing"
man      "test_statement_coverage_80"           "measure it: make coverage"
contains "test_invocation (documented)"         "README.md" "make test" \
                                                "document how to run the tests in README.md"
fi

# =========================================================================
if [[ "$LEVEL" == "all" || "$LEVEL" == "gold" ]]; then
section "GOLD — Project maturity"
man      "bus_factor >= 2"                      "list a second maintainer in MAINTAINERS.md"
man      "maintainers_active (2+ reviewers)"    "all changes reviewed by someone other than the author"
man      "code_review_standards"                "enable branch protection requiring review on main"
man      "test_statement_coverage_90"           "measure it: make coverage"
man      "test_branch_coverage_80"              "measure it: make coverage"
contains "build_reproducible"                   "docs/verification.md" "reproduc" \
                                                "document build reproducibility in docs/verification.md"
have     "hardening (security headers/policies)" "SAST_POLICY.md"
have     "hall_of_fame (researcher credit)"     "HALL_OF_FAME.md"
have     "citation metadata"                    "CITATION.cff"
fi

# =========================================================================
section "Documentation debt"
# Scan only tracked files when this is a git repository: virtualenvs, node_modules,
# and build caches are full of unrelated template syntax and would poison the count.
# grep exits 1 on no match, which pipefail would turn into a script failure, so
# every scan is wrapped in `|| true`.
scan_count() {
    local pattern="$1"
    if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
        { git -C "$REPO" grep -IoE "$pattern" -- . 2>/dev/null || true; } | wc -l
    else
        { grep -rIoE "$pattern" "$REPO" \
            --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv \
            --exclude-dir=venv --exclude-dir=target --exclude-dir=dist 2>/dev/null || true; } | wc -l
    fi
}

todo_count="$(scan_count 'TODO\(template\)')"
placeholder_count="$(scan_count '\{\{[A-Z_]+\}\}')"

if (( todo_count == 0 )); then
    ok "No TODO(template) markers left" "every section is filled in"
else
    printf '  %s•%s %s TODO(template) marker(s) still to fill in — run: make todo\n' \
        "${C_BLUE}" "${C_OFF}" "$todo_count"
fi
if (( placeholder_count > 0 )); then
    no "Unrendered {{PLACEHOLDER}} values" "$placeholder_count occurrence(s); re-run bootstrap.sh or fix by hand"
fi

# =========================================================================
total=$(( PASS + FAIL ))
pct=0
(( total > 0 )) && pct=$(( PASS * 100 / total ))

printf '\n%s%s%s\n' "${C_BOLD}" "Summary" "${C_OFF}"
printf '  %s%d passed%s   %s%d missing%s   %s%d need a human decision%s\n' \
    "${C_GREEN}" "$PASS" "${C_OFF}" "${C_RED}" "$FAIL" "${C_OFF}" "${C_YELLOW}" "$MANUAL" "${C_OFF}"
printf '  Automated criteria satisfied: %s%d%%%s\n' "${C_BOLD}" "$pct" "${C_OFF}"

if (( FAIL > 0 )); then
    printf '\n%sTo do next%s\n' "${C_BOLD}" "${C_OFF}"
    printf '  - %s\n' "${REMEDIATION[@]}"
fi

printf '\n%sRegister the project at https://www.bestpractices.dev/en/projects/new%s\n' "${C_DIM}" "${C_OFF}"
printf '%sthen put the project ID in the README badge URL.%s\n\n' "${C_DIM}" "${C_OFF}"

(( FAIL == 0 ))
