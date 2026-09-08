#!/usr/bin/env bash
#
# bootstrap.sh — scaffold a new repository from TemplateRepository.
#
#   scripts/bootstrap.sh --target ../MyProject --profile python
#   scripts/bootstrap.sh --target ../ExistingRepo --profile rust --merge
#
# The script never overwrites an existing file unless --force is given, so it is
# safe to run against a repository that already has content.
#
# Answers are recorded in <target>/.template/answers.env so the same values can
# be replayed later with --answers.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly TEMPLATE_DIR="${TEMPLATE_ROOT}/template"

# shellcheck source=lib/render.sh
source "${SCRIPT_DIR}/lib/render.sh"

declare -A VARS=()

TARGET=""
PROFILE=""
ANSWERS_FILE=""
FORCE=0
MERGE=0
DRY_RUN=0
INTERACTIVE=1

readonly C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_RED=$'\033[31m'
readonly C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_CYAN=$'\033[36m' C_OFF=$'\033[0m'

log()  { printf '%s==>%s %s\n' "${C_CYAN}" "${C_OFF}" "$*"; }
warn() { printf '%s!!!%s %s\n' "${C_YELLOW}" "${C_OFF}" "$*" >&2; }
die()  { printf '%s!!!%s %s\n' "${C_RED}" "${C_OFF}" "$*" >&2; exit 1; }

usage() {
    cat <<'USAGE'
Usage: scripts/bootstrap.sh --target <dir> [options]

Required:
  --target <dir>        Destination repository directory (created if missing).

Options:
  --profile <name>      Language profile: python | node | rust | generic.
  --answers <file>      Load answers from a previously generated answers.env.
  --set KEY=VALUE       Override a single variable (repeatable).
  --merge               Skip files that already exist in the target (default).
  --force               Overwrite existing files in the target.
  --dry-run             Print what would be written, change nothing.
  --non-interactive     Never prompt; fail if a required value is missing.
  -h, --help            Show this help.

Examples:
  scripts/bootstrap.sh --target ../NewTool --profile python
  scripts/bootstrap.sh --target ../USBGuardGUI --profile generic --merge
  scripts/bootstrap.sh --target ../NewTool --answers ../NewTool/.template/answers.env --force
USAGE
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
declare -a CLI_OVERRIDES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)          TARGET="${2:?--target needs a value}"; shift 2 ;;
        --profile)         PROFILE="${2:?--profile needs a value}"; shift 2 ;;
        --answers)         ANSWERS_FILE="${2:?--answers needs a value}"; shift 2 ;;
        --set)             CLI_OVERRIDES+=("${2:?--set needs KEY=VALUE}"); shift 2 ;;
        --merge)           MERGE=1; shift ;;
        --force)           FORCE=1; shift ;;
        --dry-run)         DRY_RUN=1; shift ;;
        --non-interactive) INTERACTIVE=0; shift ;;
        -h|--help)         usage; exit 0 ;;
        *)                 die "Unknown option: $1 (try --help)" ;;
    esac
done

[[ -n "$TARGET" ]] || { usage; die "--target is required."; }
[[ -t 0 ]] || INTERACTIVE=0

# ---------------------------------------------------------------------------
# Answer collection
# ---------------------------------------------------------------------------

# ask <KEY> <prompt> <default>
ask() {
    local key="$1" prompt="$2" default="$3" reply
    if [[ -n "${VARS[$key]:-}" ]]; then
        return 0                      # already supplied via --set or --answers
    fi
    if (( ! INTERACTIVE )); then
        [[ -n "$default" ]] || die "Missing required value for ${key} in non-interactive mode."
        VARS[$key]="$default"
        return 0
    fi
    if [[ -n "$default" ]]; then
        read -r -p "$(printf '%s%s%s [%s%s%s]: ' "${C_BOLD}" "$prompt" "${C_OFF}" "${C_DIM}" "$default" "${C_OFF}")" reply
    else
        read -r -p "$(printf '%s%s%s: ' "${C_BOLD}" "$prompt" "${C_OFF}")" reply
    fi
    VARS[$key]="${reply:-$default}"
}

load_answers() {
    local file="$1" line key value
    [[ -f "$file" ]] || die "Answers file not found: $file"
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%\"}"; value="${value#\"}"
        VARS["$key"]="$value"
    done < "$file"
}

slugify()  { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-//' -e 's/-$//'; }
acronym()  { printf '%s' "$1" | grep -oE '[A-Z]' | tr -d '\n'; }

[[ -n "$ANSWERS_FILE" ]] && load_answers "$ANSWERS_FILE"
for override in "${CLI_OVERRIDES[@]:-}"; do
    [[ -z "$override" ]] && continue
    VARS["${override%%=*}"]="${override#*=}"
done

# --- Profile -----------------------------------------------------------------
if [[ -z "$PROFILE" ]]; then
    PROFILE="${VARS[LANG_PROFILE]:-}"
fi
if [[ -z "$PROFILE" ]]; then
    if (( INTERACTIVE )); then
        printf '\n%sLanguage profile%s — python | node | rust | generic\n' "${C_BOLD}" "${C_OFF}"
        read -r -p "Profile [generic]: " PROFILE
        PROFILE="${PROFILE:-generic}"
    else
        PROFILE="generic"
    fi
fi
[[ -d "${TEMPLATE_DIR}/${PROFILE}" ]] || die "Unknown profile '${PROFILE}'. Available: $(cd "$TEMPLATE_DIR" && ls -d */ | grep -v '^common/\|^licenses/' | tr -d '/' | tr '\n' ' ')"
VARS[LANG_PROFILE]="$PROFILE"

# Profile-supplied defaults (language name, CodeQL id, ecosystem, ...).
# shellcheck source=/dev/null
source "${TEMPLATE_DIR}/${PROFILE}/profile.env"
for key in PRIMARY_LANGUAGE PRIMARY_LANGUAGE_LOGO MIN_LANG_VERSION CODEQL_LANGUAGE DEPENDABOT_ECOSYSTEM LINTER_NAME; do
    VARS[$key]="${VARS[$key]:-${!key}}"
done

# --- Identity ----------------------------------------------------------------
default_slug="$(basename "$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd || echo .)/$(basename "$TARGET")")"

printf '\n%s%s%s\n' "${C_BOLD}" "Project identity" "${C_OFF}"
ask PROJECT_SLUG  "Repository name"                      "$default_slug"
ask PROJECT_NAME  "Human-readable project name"          "${VARS[PROJECT_SLUG]}"
ask PROJECT_SHORT "Short name / acronym"                 "$(acronym "${VARS[PROJECT_NAME]}" | head -c 8)"
[[ -n "${VARS[PROJECT_SHORT]}" ]] || VARS[PROJECT_SHORT]="${VARS[PROJECT_SLUG]}"
ask PROJECT_DESC  "One-line description"                 "TODO: describe ${VARS[PROJECT_NAME]}"

case "$PROFILE" in
    python) default_pkg="$(slugify "${VARS[PROJECT_SHORT]}" | tr '-' '_')" ;;
    *)      default_pkg="$(slugify "${VARS[PROJECT_SHORT]}")" ;;
esac
ask PROJECT_PKG   "Package / module name"                "$default_pkg"
ask PROJECT_DIST  "Distribution name (registry)"         "$(slugify "${VARS[PROJECT_SLUG]}")"

printf '\n%s%s%s\n' "${C_BOLD}" "Ownership" "${C_OFF}"
ask GITHUB_OWNER   "GitHub owner"                        "$(git config --get user.github 2>/dev/null || echo onyks-os)"
ask AUTHOR_NAME    "Author name"                         "$(git config --get user.name 2>/dev/null || echo onyks)"
ask CONTACT_EMAIL  "Contact email"                       "$(git config --get user.email 2>/dev/null || echo '')"
ask SECURITY_EMAIL "Security reporting email"            "${VARS[CONTACT_EMAIL]}"
ask LICENSE_ID     "SPDX license identifier"             "MIT"

printf '\n%s%s%s\n' "${C_BOLD}" "Release & documentation" "${C_OFF}"
ask VERSION        "Initial version"                     "0.1.0"
ask DOCS_SLUG      "Documentation path segment"          "$(slugify "${VARS[PROJECT_SHORT]}")"
ask OPENSSF_PROJECT_ID "OpenSSF Best Practices project ID (0 if not registered yet)" "0"

# --- Derived values ----------------------------------------------------------
VARS[COPYRIGHT_YEAR]="${VARS[COPYRIGHT_YEAR]:-$(date +%Y)}"
VARS[DATE]="${VARS[DATE]:-$(date +%Y-%m-%d)}"
VARS[DOCS_URL]="${VARS[DOCS_URL]:-https://${VARS[GITHUB_OWNER]}.github.io/${VARS[DOCS_SLUG]}/}"
VARS[DOCS_SITE_DIR]="${VARS[DOCS_SITE_DIR]:-../${VARS[GITHUB_OWNER]}.github.io/${VARS[DOCS_SLUG]}}"
VARS[PROJECT_ENV_PREFIX]="${VARS[PROJECT_ENV_PREFIX]:-$(printf '%s' "${VARS[PROJECT_SHORT]}" | tr '[:lower:]-' '[:upper:]_')}"
# py310 / py311 style target for Ruff.
VARS[PY_TARGET]="${VARS[PY_TARGET]:-$(printf '%s' "${VARS[MIN_LANG_VERSION]}" | tr -d '.')}"
# Rust resolves a library crate by the package name with hyphens replaced by
# underscores, which is not the same string as PROJECT_PKG.
VARS[CRATE_NAME]="${VARS[CRATE_NAME]:-$(printf '%s' "${VARS[PROJECT_DIST]}" | tr '-' '_')}"

# ---------------------------------------------------------------------------
# Write out
# ---------------------------------------------------------------------------
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

declare -i written=0 skipped=0
declare -a SKIPPED_FILES=()

copy_tree() {
    local src_root="$1" rel dst
    [[ -d "$src_root" ]] || return 0
    while IFS= read -r -d '' src; do
        rel="${src#"$src_root"/}"
        # Profile metadata and gitignore fragments are handled separately.
        case "$rel" in
            profile.env|.gitignore.append) continue ;;
        esac
        dst="${TARGET}/$(render_path "$rel")"

        if [[ -e "$dst" && $FORCE -eq 0 ]]; then
            SKIPPED_FILES+=("$(render_path "$rel")")
            (( skipped += 1 ))
            continue
        fi
        if (( DRY_RUN )); then
            printf '  %swould write%s %s\n' "${C_DIM}" "${C_OFF}" "${dst#"$TARGET"/}"
        else
            render_file "$src" "$dst"
        fi
        (( written += 1 ))
    done < <(find "$src_root" -type f -print0)
}

log "Scaffolding ${C_BOLD}${VARS[PROJECT_NAME]}${C_OFF} (${PROFILE}) into ${TARGET}"
copy_tree "${TEMPLATE_DIR}/common"
copy_tree "${TEMPLATE_DIR}/${PROFILE}"

# --- .gitignore: base + profile fragment -------------------------------------
gitignore_append="${TEMPLATE_DIR}/${PROFILE}/.gitignore.append"
if [[ -f "$gitignore_append" && $DRY_RUN -eq 0 ]]; then
    if ! grep -q "^# Profile: ${PROFILE}$" "${TARGET}/.gitignore" 2>/dev/null; then
        {
            printf '\n# Profile: %s\n' "$PROFILE"
            cat "$gitignore_append"
        } >> "${TARGET}/.gitignore"
    fi
fi

# --- LICENSE ------------------------------------------------------------------
license_src="${TEMPLATE_DIR}/licenses/${VARS[LICENSE_ID]}.txt"
if [[ -f "$license_src" ]]; then
    if [[ ! -e "${TARGET}/LICENSE" || $FORCE -eq 1 ]]; then
        (( DRY_RUN )) || render_file "$license_src" "${TARGET}/LICENSE"
        (( written += 1 ))
    else
        SKIPPED_FILES+=("LICENSE"); (( skipped += 1 ))
    fi
elif [[ ! -e "${TARGET}/LICENSE" ]]; then
    warn "No bundled text for '${VARS[LICENSE_ID]}'. Fetch it from https://spdx.org/licenses/${VARS[LICENSE_ID]}.html and save it as LICENSE."
fi

# --- Record the answers for later replays ------------------------------------
if (( ! DRY_RUN )); then
    mkdir -p "${TARGET}/.template"
    {
        printf '# Generated by TemplateRepository bootstrap.sh on %s\n' "$(date -Iseconds)"
        printf '# Replay with: scripts/bootstrap.sh --target <dir> --answers <this file>\n'
        for key in $(printf '%s\n' "${!VARS[@]}" | sort); do
            printf '%s="%s"\n' "$key" "${VARS[$key]}"
        done
    } > "${TARGET}/.template/answers.env"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
printf '\n'
log "${C_GREEN}Wrote ${written} file(s)${C_OFF}, skipped ${skipped} existing."
if (( skipped > 0 )); then
    printf '%sExisting files left untouched (use --force to overwrite):%s\n' "${C_DIM}" "${C_OFF}"
    printf '  %s\n' "${SKIPPED_FILES[@]}"
fi

if (( ! DRY_RUN )); then
    leftover="$(unresolved_placeholders "$TARGET" | wc -l)"
    if (( leftover > 0 )); then
        warn "${leftover} unresolved {{PLACEHOLDER}} occurrence(s) remain — run: grep -rn '{{' ${TARGET}"
    fi
    todos="$(grep -rIo --exclude-dir=.git 'TODO(template)' "$TARGET" 2>/dev/null | wc -l)"
    printf '\n%sNext steps%s\n' "${C_BOLD}" "${C_OFF}"
    printf '  1. cd %s\n' "$TARGET"
    printf '  2. git init && git add -A && git commit -s -m "chore: scaffold from TemplateRepository"\n'
    printf '  3. make setup && make install-hooks\n'
    printf '  4. make todo          # %s documentation sections to fill in\n' "$todos"
    printf '  5. %s/scripts/openssf-audit.sh %s   # badge readiness report\n' "$TEMPLATE_ROOT" "$TARGET"
    printf '\n'
fi
