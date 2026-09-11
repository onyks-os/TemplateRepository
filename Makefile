# TemplateRepository — scaffolder for new repositories.
#
# This Makefile drives the template itself. The Makefile that ends up *inside*
# a generated repository is template/common/Makefile.

SHELL := /bin/bash
.DEFAULT_GOAL := help

TEMPLATE_DIR := template
PROFILES     := $(notdir $(patsubst %/,%,$(filter-out $(TEMPLATE_DIR)/common/ $(TEMPLATE_DIR)/licenses/,$(wildcard $(TEMPLATE_DIR)/*/))))

.PHONY: help new dry-run audit test check check-shell check-placeholders check-profiles \
        check-pins verify-pins pin-actions list-vars profiles clean

##@ General

help: ## Show this help
	@printf "\n\033[1mTemplateRepository\033[0m — scaffold a repository that is OSS-ready from commit one\n\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5); next } \
		/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		' $(MAKEFILE_LIST)
	@printf "\n\033[1mExamples\033[0m\n"
	@printf "  make new TARGET=../MyTool PROFILE=python\n"
	@printf "  make new TARGET=../ExistingRepo PROFILE=generic     # merges, never overwrites\n"
	@printf "  make audit REPO=../TransparentTorProxy\n"
	@printf "  make test                                            # scaffold every profile and audit it\n\n"

profiles: ## List the available language profiles
	@printf "Available profiles: %s\n" "$(PROFILES)"

##@ Scaffolding

new: ## Scaffold a repository — make new TARGET=<dir> [PROFILE=<name>]
	@if [ -z "$(TARGET)" ]; then \
		echo "Usage: make new TARGET=../MyProject [PROFILE=python|node|rust|generic]"; exit 2; \
	fi
	@./scripts/bootstrap.sh --target "$(TARGET)" $(if $(PROFILE),--profile "$(PROFILE)",) $(BOOTSTRAP_ARGS)

dry-run: ## Preview a scaffold without writing anything — same arguments as `new`
	@if [ -z "$(TARGET)" ]; then \
		echo "Usage: make dry-run TARGET=../MyProject [PROFILE=python]"; exit 2; \
	fi
	@./scripts/bootstrap.sh --target "$(TARGET)" $(if $(PROFILE),--profile "$(PROFILE)",) --dry-run $(BOOTSTRAP_ARGS)

##@ Auditing

audit: ## OpenSSF Best Practices readiness report — make audit REPO=<dir>
	@./scripts/openssf-audit.sh "$(or $(REPO),.)" $(if $(LEVEL),--level $(LEVEL),)

##@ Testing

# The template is verified through its output, not its sources: the suite
# scaffolds every profile into a temporary directory and asserts on the result.
test: ## Run the end-to-end test suite
	@./tests/run-tests.sh $(if $(VERBOSE),-v,)

##@ Template maintenance

check: check-shell check-profiles check-placeholders ## Verify the template itself is consistent
	@echo "==> Template is consistent."

check-shell: ## ShellCheck every script in this repository
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "==> ShellCheck..."; \
		shellcheck -x scripts/*.sh scripts/lib/*.sh tests/*.sh; \
	else \
		echo "==> shellcheck not installed; running bash -n instead"; \
		for f in scripts/*.sh scripts/lib/*.sh tests/*.sh; do bash -n "$$f" || exit 1; done; \
	fi

check-profiles: ## Verify every profile implements the full lang-* target contract
	@echo "==> Checking the lang-* contract..."
	@status=0; \
	for p in $(PROFILES); do \
		mk="$(TEMPLATE_DIR)/$$p/make/$$p.mk"; \
		if [ ! -f "$$mk" ]; then echo "  MISSING $$mk"; status=1; continue; fi; \
		for t in lang-setup lang-lint lang-format lang-test lang-test-integration lang-fuzz lang-audit lang-build lang-clean; do \
			grep -q "^$$t:" "$$mk" || { echo "  $$p: missing target $$t"; status=1; }; \
		done; \
		[ -f "$(TEMPLATE_DIR)/$$p/profile.env" ] || { echo "  $$p: missing profile.env"; status=1; }; \
	done; \
	[ $$status -eq 0 ] && echo "  All profiles implement the contract."; \
	exit $$status

check-placeholders: ## List every {{PLACEHOLDER}} used, so none goes unbound
	@echo "==> Placeholders referenced by the template:"
	@grep -rhoE '\{\{[A-Z_]+\}\}' $(TEMPLATE_DIR) 2>/dev/null | sort -u | sed 's/^/  /'
	@echo ""
	@echo "==> Every name above must be assigned in scripts/bootstrap.sh or a profile.env."
	@missing=0; \
	for v in $$(grep -rhoE '\{\{[A-Z_]+\}\}' $(TEMPLATE_DIR) 2>/dev/null | tr -d '{}' | sort -u); do \
		grep -qE "(VARS\[$$v\]|ask $$v|^$$v=)" scripts/bootstrap.sh $(TEMPLATE_DIR)/*/profile.env \
			|| { echo "  UNBOUND: $$v"; missing=1; }; \
	done; \
	[ $$missing -eq 0 ] && echo "  All placeholders are bound." || exit 1

list-vars: check-placeholders ## Alias for check-placeholders

check-pins: ## Report action pins under template/ that have fallen behind
	@./scripts/pin-actions.sh --check

verify-pins: ## Assert every pinned SHA in every workflow is a real commit
	@./scripts/pin-actions.sh --verify

pin-actions: ## Refresh those pins (stays within the current major version)
	@./scripts/pin-actions.sh $(if $(ALLOW_MAJOR),--allow-major,)

clean: ## Remove scratch output
	@rm -rf .scratch/
