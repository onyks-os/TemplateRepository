# {{PROJECT_NAME}} ({{PROJECT_SHORT}}) — developer entrypoint.
#
# Every target is documented inline; run `make help` for the full list.
# Logic lives in the modular fragments under make/ so that this file stays readable:
#
#   make/common.mk   — environment, help, housekeeping, TODO tracking
#   make/quality.mk  — lint, format, audit, security gates
#   make/docs.mk     — MkDocs site and ADR scaffolding
#   make/release.mk  — versioning, build, SBOM, checksums, signing
#   make/{{LANG_PROFILE}}.mk  — language-specific implementation of the target contract
#   make/local.mk    — optional, git-ignored, machine-local overrides

SHELL := /bin/bash
.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Project identity — the single source of truth for scripts and workflows.
# ---------------------------------------------------------------------------
PROJECT_NAME  := {{PROJECT_NAME}}
PROJECT_SHORT := {{PROJECT_SHORT}}
PROJECT_SLUG  := {{PROJECT_SLUG}}
PROJECT_PKG   := {{PROJECT_PKG}}
PROJECT_DIST  := {{PROJECT_DIST}}
GITHUB_OWNER  := {{GITHUB_OWNER}}
VERSION       := {{VERSION}}

# Directories that hold first-party source, tests, and shell scripts.
SRC_DIRS     := {{PROJECT_PKG}}
TEST_DIRS    := tests
SCRIPT_DIRS  := scripts

include make/common.mk
include make/quality.mk
include make/docs.mk
include make/release.mk
include make/{{LANG_PROFILE}}.mk
-include make/local.mk
