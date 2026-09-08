#!/usr/bin/env bash
#
# verify.sh — the full local gate, callable from CI or by hand.
#
# `make verify` delegates here so that the same sequence runs in every context.
set -euo pipefail

# Declared and assigned separately: `readonly x="$(cmd)"` masks the command's
# exit status, so a failing cd would go unnoticed (ShellCheck SC2155). The
# template's own `make lint` runs ShellCheck, so this shipped a scaffolded
# repository whose first lint run failed on a file it had just been given.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_ROOT

cd "${REPO_ROOT}"

log() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[31m!!! %s\033[0m\n' "$*" >&2; exit 1; }

log "Linting"
make lint || fail "Lint failed."

log "Unit tests"
make test || fail "Unit tests failed."

log "Dependency audit"
make audit || fail "Dependency audit failed."

log "Documentation build"
make docs-build || fail "Documentation build failed."

printf '\n\033[32m==> All checks passed.\033[0m\n'
