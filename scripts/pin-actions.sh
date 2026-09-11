#!/usr/bin/env bash
#
# pin-actions.sh — keep the action pins in template/**/.github/workflows/ fresh.
#
#   scripts/pin-actions.sh --check          report stale pins, change nothing
#   scripts/pin-actions.sh --verify          assert every pin resolves to a real commit
#   scripts/pin-actions.sh                   rewrite stale pins in place
#   scripts/pin-actions.sh --allow-major     also cross a major version boundary
#
# Every action the template ships is pinned to a commit SHA, because a tag is a
# movable pointer and a scaffolded repository inherits whatever it points at.
# Dependabot cannot maintain those pins: it reads .github/workflows/ at the root
# of a repository, and the template's copies live under template/, where they are
# inert YAML rather than workflows this repository runs. This script is the
# replacement for that automation.
#
# The trailing comment on each `uses:` line is not decoration — it records which
# version the SHA corresponds to, and this script reads it to decide what "newer"
# means. Keep it accurate.
#
# Requires the GitHub CLI (`gh`), authenticated.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT

CHECK_ONLY=0
ALLOW_MAJOR=0
VERIFY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)       CHECK_ONLY=1; shift ;;
        --verify)      VERIFY=1; shift ;;
        --allow-major) ALLOW_MAJOR=1; shift ;;
        -h|--help)     sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)             echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
    esac
done

command -v gh >/dev/null 2>&1 || {
    echo "pin-actions.sh needs the GitHub CLI. Install gh and run 'gh auth login'." >&2
    exit 1
}

readonly C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_RED=$'\033[31m'
readonly C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_OFF=$'\033[0m'

declare -i STALE=0 FRESH=0 UPDATED=0

# latest_tag <owner/repo> <current-tag> — the newest semver tag, held to the
# current major unless --allow-major. Prints nothing when there is no candidate.
latest_tag() {
    local repo="$1" current="$2" major filter
    major="$(printf '%s' "$current" | sed -nE 's/^v?([0-9]+)\..*/\1/p')"
    if (( ALLOW_MAJOR )) || [[ -z "$major" ]]; then
        filter='^v?[0-9]+\.[0-9]+\.[0-9]+$'
    else
        filter="^v?${major}\.[0-9]+\.[0-9]+$"
    fi
    gh api "repos/${repo}/tags" --paginate --jq '.[].name' 2>/dev/null \
        | grep -E "$filter" \
        | sed 's/^v//' | sort -V | tail -1 \
        | sed 's/^/v/'
}

# sha_for <owner/repo> <ref>
sha_for() { gh api "repos/${1}/commits/${2}" --jq .sha 2>/dev/null; }

# --- verify -----------------------------------------------------------------
# A 40-hex string looks like a pin whether or not it names a commit that exists.
# A typo, a SHA copied from a fork, or one written from memory fails only when
# the workflow runs, which for a release workflow means at the worst moment.
# Unlike the rest of this script, verification covers every workflow in the tree,
# including this repository's own — Dependabot maintains those, but nothing
# checks that a hand-edited pin points anywhere real.
if (( VERIFY )); then
    printf '%s%s%s\n' "${C_BOLD}" "Verifying every pinned SHA resolves" "${C_OFF}"
    declare -i broken=0 good=0
    while IFS= read -r ref; do
        sha="${ref##*@}"
        path="${ref%@*}"
        repo="$(printf '%s' "$path" | cut -d/ -f1,2)"
        if [[ "$(sha_for "$repo" "$sha")" == "$sha" ]]; then
            (( good += 1 ))
        else
            (( broken += 1 ))
            printf '  %s✘%s %-50s %s%s%s\n' "${C_RED}" "${C_OFF}" "$path" "${C_DIM}" "${sha:0:12} does not exist in ${repo}" "${C_OFF}"
        fi
    done < <(find "$REPO_ROOT" -type d -name .git -prune -o \
                -type f -path '*/.github/workflows/*' \( -name '*.yml' -o -name '*.yaml' \) \
                -exec grep -ohE 'uses: [^@[:space:]]+@[0-9a-f]{40}' {} + 2>/dev/null \
             | sed 's/uses: //' | sort -u)

    printf '\n%s%s%s\n  %s%d resolve%s   %s%d broken%s\n' \
        "${C_BOLD}" "Summary" "${C_OFF}" \
        "${C_GREEN}" "$good" "${C_OFF}" "${C_RED}" "$broken" "${C_OFF}"
    exit $(( broken > 0 ))
fi

printf '%s%s%s\n' "${C_BOLD}" "Action pins in template/**/.github/workflows/" "${C_OFF}"

mapfile -t FILES < <(find "${REPO_ROOT}/template" -type f -path '*/.github/workflows/*' \
    \( -name '*.yml' -o -name '*.yaml' \) | sort)

# One resolution per distinct action, cached: the same action appears in a dozen
# workflows and the API is rate limited.
declare -A RESOLVED=()

for file in "${FILES[@]}"; do
    # Read the file fully before any rewrite: `sed -i` swaps the inode underneath
    # an open descriptor, and streaming a file while editing it is a trap even
    # where it happens to work.
    mapfile -t LINES < "$file"
    for line in "${LINES[@]}"; do
        # uses: owner/repo[/subpath]@<sha> # <version-or-branch>
        [[ "$line" =~ uses:[[:space:]]*([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(/[^@[:space:]]*)?@([0-9a-f]{40})[[:space:]]*#[[:space:]]*([^[:space:]]+) ]] || continue
        repo="${BASH_REMATCH[1]}"
        subpath="${BASH_REMATCH[2]}"
        old_sha="${BASH_REMATCH[3]}"
        old_ver="${BASH_REMATCH[4]}"
        key="${repo}@${old_ver}"

        if [[ -z "${RESOLVED[$key]:-}" ]]; then
            if [[ "$old_ver" =~ ^v?[0-9]+\.[0-9]+ ]]; then
                new_ver="$(latest_tag "$repo" "$old_ver")"
                [[ -z "$new_ver" ]] && new_ver="$old_ver"
            else
                # A branch pin: the branch name is the version, and only the
                # commit it points at can move.
                new_ver="$old_ver"
            fi
            new_sha="$(sha_for "$repo" "$new_ver")"
            RESOLVED[$key]="${new_sha:-}|${new_ver}"
        fi

        IFS='|' read -r new_sha new_ver <<< "${RESOLVED[$key]}"
        if [[ -z "$new_sha" ]]; then
            printf '  %s?%s %-50s %scould not resolve%s\n' \
                "${C_YELLOW}" "${C_OFF}" "${repo}${subpath}" "${C_DIM}" "${C_OFF}"
            continue
        fi

        if [[ "$new_sha" == "$old_sha" ]]; then
            (( FRESH += 1 ))
            continue
        fi

        (( STALE += 1 ))
        printf '  %s↑%s %-50s %s%s → %s%s\n' \
            "${C_YELLOW}" "${C_OFF}" "${repo}${subpath}" "${C_DIM}" "$old_ver" "$new_ver" "${C_OFF}"
        printf '      %s%s%s\n' "${C_DIM}" "${file#"$REPO_ROOT"/}" "${C_OFF}"

        if (( ! CHECK_ONLY )); then
            # The SHA alone is enough to identify the line: it is unique per
            # action version, so a targeted replace cannot hit the wrong action.
            sed -i "s|${repo}${subpath}@${old_sha}[[:space:]]*#[[:space:]]*${old_ver}|${repo}${subpath}@${new_sha} # ${new_ver}|g" "$file"
            (( UPDATED += 1 ))
        fi
    done
done

printf '\n%s%s%s\n' "${C_BOLD}" "Summary" "${C_OFF}"
printf '  %s%d up to date%s   %s%d stale%s\n' \
    "${C_GREEN}" "$FRESH" "${C_OFF}" "${C_YELLOW}" "$STALE" "${C_OFF}"

if (( CHECK_ONLY && STALE > 0 )); then
    printf '\n%sRun scripts/pin-actions.sh to apply, then re-run the test suite.%s\n' "${C_DIM}" "${C_OFF}"
    exit 1
fi
if (( UPDATED > 0 )); then
    printf '\n%s%d pin(s) rewritten.%s Review the diff and run: make test\n' "${C_BOLD}" "$UPDATED" "${C_OFF}"
fi
