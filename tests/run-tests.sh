#!/usr/bin/env bash
#
# run-tests.sh — the template's own test suite.
#
#   tests/run-tests.sh [-v]
#
# Everything here is end to end: scaffold into a throwaway directory and assert on
# what came out. The unit under test is the pair of scripts plus the template
# tree, and the only interface that matters is the generated repository, so that
# is what gets inspected.
#
# No dependency beyond bash, git, and coreutils. shellcheck is used when present.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT
readonly BOOTSTRAP="${REPO_ROOT}/scripts/bootstrap.sh"
readonly AUDIT="${REPO_ROOT}/scripts/openssf-audit.sh"
readonly FIXTURES="${SCRIPT_DIR}/fixtures"
readonly PROFILES=(python node rust generic)

VERBOSE=0
[[ "${1:-}" == "-v" ]] && VERBOSE=1

readonly C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_RED=$'\033[31m'
readonly C_GREEN=$'\033[32m' C_OFF=$'\033[0m'

declare -i PASSED=0 FAILED=0
declare -a FAILURES=()

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

pass() { (( PASSED += 1 )); printf '  %s✔%s %s\n' "${C_GREEN}" "${C_OFF}" "$1"; }
fail() {
    (( FAILED += 1 )); FAILURES+=("$1")
    printf '  %s✘%s %s\n' "${C_RED}" "${C_OFF}" "$1"
    [[ -n "${2:-}" ]] && printf '      %s%s%s\n' "${C_DIM}" "$2" "${C_OFF}"
    return 0
}

# check <description> <detail-shown-on-failure> <command...>
# The command is run by the harness rather than before it, so the assertion and
# its exit status cannot drift apart.
check() {
    local desc="$1" detail="$2"; shift 2
    if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc" "$detail"; fi
}

# check_not — passes when the command fails. For assertions of the form
# "this must NOT be reported".
check_not() {
    local desc="$1" detail="$2"; shift 2
    if "$@" >/dev/null 2>&1; then fail "$desc" "$detail"; else pass "$desc"; fi
}

describe() { printf '\n%s%s%s\n' "${C_BOLD}" "$1" "${C_OFF}"; }

# scaffold <dest> <profile> [extra bootstrap args...] — non-interactive, quiet.
scaffold() {
    local dest="$1" profile="$2"; shift 2
    "$BOOTSTRAP" --target "$dest" --profile "$profile" --non-interactive \
        --set PROJECT_NAME="Test Project" \
        --set PROJECT_SHORT=TP \
        --set PROJECT_DESC="A project used by the template test suite" \
        --set CONTACT_EMAIL="test@example.invalid" \
        --set SECURITY_EMAIL="test@example.invalid" \
        "$@" > "${WORK}/last-bootstrap.log" 2>&1
}

# scaffold_bare <dest> — scaffold the way a CI runner or a fresh container does:
# no global or system git config, and a working directory that is not a git
# repository, so `git config --get user.email` returns nothing. Running this from
# inside a checkout that happens to have a local user.email set — which is the
# normal state of a developer machine — hides the failure entirely.
scaffold_bare() {
    ( cd "$WORK" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
        "$BOOTSTRAP" --target "$1" --profile generic --non-interactive \
        --set PROJECT_NAME="alllowercase" )
}

# grep helpers used as check commands, so the assertion reads as a sentence.
reports()     { printf '%s' "$2" | grep -q "✘.*$1"; }
asks_human()  { printf '%s' "$2" | grep -q "?.*$1"; }

printf '%s%s%s\n' "${C_BOLD}" "TemplateRepository test suite" "${C_OFF}"
printf '%s%s%s\n' "${C_DIM}" "workdir: ${WORK}" "${C_OFF}"

# ---------------------------------------------------------------------------
describe "Scaffolding — every profile produces a complete repository"
# ---------------------------------------------------------------------------
for profile in "${PROFILES[@]}"; do
    dest="${WORK}/${profile}"
    check "${profile}: bootstrap exits 0" "see ${WORK}/last-bootstrap.log" \
        scaffold "$dest" "$profile"

    # An unrendered placeholder is the one failure mode that makes a generated
    # repository actively broken rather than merely incomplete.
    leftovers="$(grep -rIl '{{[A-Z_]\+}}' "$dest" 2>/dev/null | head -5)"
    check "${profile}: no unrendered {{PLACEHOLDER}} in the output" "$leftovers" \
        test -z "$leftovers"

    check "${profile}: answers.env recorded for a later replay" "" \
        test -f "${dest}/.template/answers.env"

    missing=""
    for required in README.md LICENSE Makefile SECURITY.md CONTRIBUTING.md \
                    .github/workflows/ci.yml .github/dependabot.yml; do
        [[ -e "${dest}/${required}" ]] || missing+=" ${required}"
    done
    check "${profile}: the load-bearing files exist" "missing:${missing}" \
        test -z "$missing"

    # setup-python's pip cache fails the docs job when no dependency file
    # matches, which is every profile without a pyproject.toml. It must be
    # keyed on the pinned documentation toolchain, and that file must exist.
    check "${profile}: docs job keys its pip cache on docs/requirements.txt" "" \
        grep -q 'cache-dependency-path: docs/requirements.txt' "${dest}/.github/workflows/docs.yml"
    check "${profile}: docs/requirements.txt pins the documentation toolchain" "" \
        grep -q '^mkdocs-material==' "${dest}/docs/requirements.txt"
done

# ---------------------------------------------------------------------------
describe "Scaffolding — the write modes behave as documented"
# ---------------------------------------------------------------------------
scaffold "${WORK}/python" python
check "a second run into the same target writes nothing" \
    "$(tail -3 "${WORK}/last-bootstrap.log")" \
    grep -q 'Wrote 0 file(s)' "${WORK}/last-bootstrap.log"

# Checking the message is not the same as checking the status. A merge run into
# an existing repository — the documented way to pull template fixes forward —
# printed its summary and then exited non-zero, so every caller that tested the
# exit code saw a failure.
check "a second run exits 0" "$(tail -3 "${WORK}/last-bootstrap.log")" \
    scaffold "${WORK}/python" python

scaffold "${WORK}/dryrun" python --dry-run
check "--dry-run writes no files" "" \
    test -z "$(ls -A "${WORK}/dryrun" 2>/dev/null)"

marker="${WORK}/python/README.md"
printf 'LOCAL EDIT\n' > "$marker"
scaffold "${WORK}/python" python
check "the default mode never overwrites an existing file" "" \
    grep -q 'LOCAL EDIT' "$marker"

scaffold "${WORK}/python" python --force
check_not "--force does overwrite" "README.md kept the local edit" \
    grep -q 'LOCAL EDIT' "$marker"

check_not "an unknown profile is rejected" "bootstrap accepted a profile that does not exist" \
    "$BOOTSTRAP" --target "${WORK}/nope" --profile nosuchprofile --non-interactive

# Two defaults that used to be empty, and an empty default aborts a
# non-interactive run. An all-lowercase name has no acronym; a machine with no
# git identity has no email to borrow. Both must fall back rather than refuse.
check "an all-lowercase project name scaffolds non-interactively" "" \
    "$BOOTSTRAP" --target "${WORK}/lowercase" --profile generic --non-interactive \
        --set PROJECT_NAME="alllowercase"

check "scaffolding works on a machine with no git identity" \
    "$(scaffold_bare "${WORK}/no-identity" 2>&1 | tail -2)" \
    scaffold_bare "${WORK}/no-identity"

# ---------------------------------------------------------------------------
describe "Scaffolding — an answers file reproduces the same repository"
# ---------------------------------------------------------------------------
check "replaying answers.env exits 0" "" \
    "$BOOTSTRAP" --target "${WORK}/replay" --profile python --non-interactive \
        --answers "${WORK}/python/.template/answers.env"

# answers.env itself carries a generation timestamp, so it is excluded.
diff -r -x answers.env "${WORK}/python" "${WORK}/replay" > "${WORK}/replay.diff" 2>&1
check "the replayed repository is byte-identical" "$(head -5 "${WORK}/replay.diff")" \
    test ! -s "${WORK}/replay.diff"

# ---------------------------------------------------------------------------
describe "Audit — a generated repository satisfies every automated criterion"
# ---------------------------------------------------------------------------
for profile in "${PROFILES[@]}"; do
    dest="${WORK}/${profile}"
    git -C "$dest" init -q 2>/dev/null
    audit_out="$("$AUDIT" "$dest" --quiet 2>&1)"
    missing_count="$(printf '%s' "$audit_out" | grep -oE '[0-9]+ missing' | grep -oE '^[0-9]+')"
    check "${profile}: audit reports 0 missing criteria" \
        "reported '${missing_count:-<unparsed>}' missing" \
        test "${missing_count:-x}" = "0"
done

# The debt scan reads a scaffolded repository before anything is committed, so it
# has to look at untracked files or it silently reports no debt at all.
todo_line="$("$AUDIT" "${WORK}/generic" 2>&1 | grep 'TODO(template)')"
check "the debt scan sees TODOs in an uncommitted repository" "$todo_line" \
    grep -qE '[1-9][0-9]* TODO' <<< "$todo_line"

# ---------------------------------------------------------------------------
describe "Audit — the workflow-safety checks detect what they claim to"
# ---------------------------------------------------------------------------
danger="${WORK}/danger"
mkdir -p "${danger}/.github/workflows"
cp "${FIXTURES}/dangerous-workflow.yml" "${danger}/.github/workflows/"
danger_out="$("$AUDIT" "$danger" --level passing 2>&1)"

for expected in \
    "dangerous_workflow (untrusted checkout)" \
    "script injection in run: blocks" \
    "token_permissions (least privilege)" \
    "pinned_dependencies (actions by SHA)"
do
    check "the dangerous fixture trips: ${expected}" \
        "$(printf '%s' "$danger_out" | sed -n '/Workflow safety/,$p')" \
        reports "$expected" "$danger_out"
done

safe="${WORK}/safe"
mkdir -p "${safe}/.github/workflows"
cp "${FIXTURES}/safe-workflow.yml" "${safe}/.github/workflows/"
safe_out="$("$AUDIT" "$safe" --level passing 2>&1)"

# pull_request_target without an untrusted checkout is a judgement call, not a
# failure: the audit must ask for a human rather than either passing or failing it.
check "the safe fixture is referred to a human, not failed" \
    "$(printf '%s' "$safe_out" | grep dangerous_workflow)" \
    asks_human "dangerous_workflow (pull_request_target)" "$safe_out"

check_not "an env:-passed untrusted value is not flagged as injection" \
    "the safe fixture was reported as a script injection" \
    reports "script injection" "$safe_out"

# ---------------------------------------------------------------------------
describe "Template sources — invariants a new workflow could quietly break"
# ---------------------------------------------------------------------------
unpinned="$(grep -rhoE '^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*[^[:space:]]+' \
    "${REPO_ROOT}"/template/*/.github/workflows/*.yml 2>/dev/null \
    | sed -E 's/.*uses:[[:space:]]*//' | grep -vE '@[0-9a-f]{40}$' | sort -u)"
check "every action in every shipped workflow is pinned to a SHA" "$unpinned" \
    test -z "$unpinned"

# Match the trigger key, not the word: dependency-review.yml explains at length
# why it does *not* use pull_request_target, and prose must not trip the check.
prt="$(grep -rlE '^[[:space:]]*pull_request_target:' "${REPO_ROOT}"/template/*/.github/workflows/*.yml 2>/dev/null)"
check "no shipped workflow uses pull_request_target" "$prt" \
    test -z "$prt"

# The scaffolder binds placeholders from a fixed list; one that nothing assigns
# is rendered as literal {{BRACES}} into the generated repository.
unbound=""
while IFS= read -r var; do
    grep -qE "(VARS\[${var}\]|ask ${var}|^${var}=)" \
        "${REPO_ROOT}/scripts/bootstrap.sh" "${REPO_ROOT}"/template/*/profile.env 2>/dev/null \
        || unbound+=" ${var}"
done < <(grep -rhoE '\{\{[A-Z_]+\}\}' "${REPO_ROOT}/template" 2>/dev/null | tr -d '{}' | sort -u)
check "every placeholder used by the template is bound" "unbound:${unbound}" \
    test -z "$unbound"

# Each profile must implement the whole lang-* contract, or `make test` in a
# generated repository fails on a missing target rather than on a real defect.
contract_gaps=""
for profile in "${PROFILES[@]}"; do
    mk="${REPO_ROOT}/template/${profile}/make/${profile}.mk"
    [[ -f "$mk" ]] || { contract_gaps+=" ${profile}:no-makefile"; continue; }
    for target in lang-setup lang-lint lang-format lang-test lang-test-integration \
                  lang-fuzz lang-audit lang-build lang-clean; do
        grep -q "^${target}:" "$mk" || contract_gaps+=" ${profile}:${target}"
    done
done
check "every profile implements the full lang-* contract" "gaps:${contract_gaps}" \
    test -z "$contract_gaps"

# ---------------------------------------------------------------------------
describe "Structured files — in the sources, and in what they render to"
# ---------------------------------------------------------------------------
# Two failure modes, and the second is only visible after rendering.
#
# A stray `---` in the middle of a config splits it into two documents, and every
# consumer reads only the first. Nothing errors; the second half is simply
# ignored. That is how .codacy.yml shipped with its entire engines: block dead.
#
# And a template file can be valid YAML with its placeholders in place and invalid
# once they are filled: the default description is "TODO: describe <project>", and
# an unquoted YAML value containing ": " is a syntax error. Every generated
# mkdocs.yml was broken that way, which `mkdocs build --strict` in the shipped
# docs workflow would have failed on. Checking the sources alone cannot see it,
# so the rendered repositories are checked too.
if python3 -c 'import yaml' 2>/dev/null; then
    python3 - "$REPO_ROOT" "${WORK}/python" "${WORK}/node" "${WORK}/rust" "${WORK}/generic" \
        > "${WORK}/yaml.log" 2>&1 <<'PYEOF'
import json, pathlib, sys, yaml

try:
    import tomllib
except ImportError:
    tomllib = None

bad = []

class Lenient(yaml.SafeLoader):
    """mkdocs.yml legitimately carries !!python/name: tags."""

Lenient.add_multi_constructor("", lambda loader, suffix, node: None)
Lenient.add_multi_constructor("tag:yaml.org,2002:python/name:",
                              lambda loader, suffix, node: None)

SKIP = {".git", "node_modules", ".venv", "venv", "target", "dist", "site"}
JSONC = __import__("re").compile(r"^(tsconfig.*|jsconfig.*|devcontainer)\.json$")

def check(root: pathlib.Path, render: bool) -> None:
    """render=True for template sources, whose placeholders are not yet values."""
    for path in sorted(root.rglob("*")):
        if not path.is_file() or set(path.relative_to(root).parts) & SKIP:
            continue
        rel = f"{root.name}/{path.relative_to(root)}" if not render else str(path.relative_to(root))
        text = path.read_text(errors="replace")
        if render:
            text = text.replace("{{", "PLACEHOLDER_").replace("}}", "_PLACEHOLDER")

        if path.suffix in {".yml", ".yaml"} or path.name.endswith(".cff"):
            try:
                docs = list(yaml.load_all(text, Loader=Lenient))
            except Exception as exc:
                bad.append(f"{rel}: {str(exc).splitlines()[0]}")
                continue
            if len(docs) > 1:
                bad.append(f"{rel}: parses as {len(docs)} documents; a consumer reads only the first")
        elif path.suffix == ".json" and not JSONC.match(path.name):
            # tsconfig.json and friends are JSONC by design — TypeScript accepts
            # comments and trailing commas there, and a strict parser must not
            # call that a defect.
            try:
                json.loads(text)
            except Exception as exc:
                bad.append(f"{rel}: {str(exc).splitlines()[0]}")
        elif path.suffix == ".toml" and tomllib is not None:
            try:
                tomllib.loads(text)
            except Exception as exc:
                bad.append(f"{rel}: {str(exc).splitlines()[0]}")

check(pathlib.Path(sys.argv[1]), render=True)
for generated in sys.argv[2:]:
    root = pathlib.Path(generated)
    if root.is_dir():
        check(root, render=False)

for line in bad:
    print(line)
sys.exit(1 if bad else 0)
PYEOF
    check "every YAML, JSON and TOML file parses — sources and rendered output" \
        "$(head -10 "${WORK}/yaml.log")" \
        test ! -s "${WORK}/yaml.log"
else
    pass "structured-file check skipped (python3 with PyYAML not available)"
fi

# ---------------------------------------------------------------------------
describe "Shell scripts"
# ---------------------------------------------------------------------------
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x "${REPO_ROOT}"/scripts/*.sh "${REPO_ROOT}"/scripts/lib/*.sh \
        "${SCRIPT_DIR}"/*.sh > "${WORK}/shellcheck.log" 2>&1
    check "shellcheck is clean" "$(head -20 "${WORK}/shellcheck.log")" \
        test ! -s "${WORK}/shellcheck.log"
else
    syntax_errors=""
    for f in "${REPO_ROOT}"/scripts/*.sh "${REPO_ROOT}"/scripts/lib/*.sh "${SCRIPT_DIR}"/*.sh; do
        bash -n "$f" 2>/dev/null || syntax_errors+=" $(basename "$f")"
    done
    check "bash -n is clean (shellcheck not installed)" "$syntax_errors" \
        test -z "$syntax_errors"
fi

# ---------------------------------------------------------------------------
printf '\n%s%s%s\n' "${C_BOLD}" "Summary" "${C_OFF}"
printf '  %s%d passed%s   %s%d failed%s\n' \
    "${C_GREEN}" "$PASSED" "${C_OFF}" "${C_RED}" "$FAILED" "${C_OFF}"

if (( FAILED > 0 )); then
    printf '\n%sFailed%s\n' "${C_BOLD}" "${C_OFF}"
    printf '  - %s\n' "${FAILURES[@]}"
    (( VERBOSE )) && { printf '\n%sLast bootstrap log%s\n' "${C_BOLD}" "${C_OFF}"; cat "${WORK}/last-bootstrap.log"; }
    exit 1
fi
printf '\n'
