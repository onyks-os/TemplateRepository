#!/usr/bin/env bash
#
# render.sh — placeholder substitution engine shared by the template scripts.
#
# Substitution is done with pure Bash parameter expansion rather than sed, so
# that values containing slashes, ampersands, or backslashes need no escaping.
# Only keys registered in the VARS map are replaced: GitHub Actions expressions
# such as ${{ github.ref }} pass through untouched.

# Guard against double sourcing.
[[ -n "${_TPL_RENDER_SH:-}" ]] && return 0
_TPL_RENDER_SH=1

# render_string <text> -> stdout
render_string() {
    local content="$1" key
    for key in "${!VARS[@]}"; do
        content=${content//"{{${key}}}"/${VARS[$key]}}
    done
    printf '%s' "$content"
}

# is_text_file <path> — true when the file is safe to substitute into.
is_text_file() {
    grep -Iq . "$1" 2>/dev/null
}

# render_file <src> <dst> — substitute placeholders, or copy verbatim if binary.
render_file() {
    local src="$1" dst="$2" content
    mkdir -p "$(dirname "$dst")"

    if ! is_text_file "$src"; then
        cp -p "$src" "$dst"
        return 0
    fi

    # read -d '' returns non-zero at EOF but still fills the variable, and unlike
    # $(<file) it preserves trailing newlines exactly.
    IFS= read -r -d '' content < "$src" || true
    render_string "$content" > "$dst"

    # Preserve the executable bit so scripts stay runnable.
    [[ -x "$src" ]] && chmod +x "$dst"
    return 0
}

# render_path <path> -> stdout — substitute placeholders appearing in a filename.
render_path() {
    local path="$1"
    path=${path//__PKG__/${VARS[PROJECT_PKG]}}
    render_string "$path"
}

# unresolved_placeholders <dir> — print every {{KEY}} left behind, with location.
unresolved_placeholders() {
    grep -rInoE '\{\{[A-Z_]+\}\}' "$1" \
        --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv \
        2>/dev/null || true
}
