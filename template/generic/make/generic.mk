# ---------------------------------------------------------------------------
# generic.mk — placeholder implementation of the lang-* target contract.
#
# Every target below is a no-op that announces itself. Replace each body with
# the real command for your toolchain; the rest of the Makefile, the CI
# workflows, and `make verify` will then work unchanged.
#
# Contract:
#   lang-setup             bootstrap the dev environment
#   lang-lint              lint, format-check, and type-check the source
#   lang-format            auto-format and auto-fix
#   lang-test              fast unit tests, no privileges
#   lang-test-integration  integration tests
#   lang-fuzz              property-based / fuzz tests
#   lang-audit             dependency vulnerability scan
#   lang-build             produce artifacts into $(DIST_DIR)
#   lang-clean             remove language-specific caches and artifacts
# ---------------------------------------------------------------------------

.PHONY: lang-setup lang-lint lang-format lang-test lang-test-integration lang-fuzz lang-audit lang-build lang-clean

define _todo
	@echo "==> [$(PROJECT_SHORT)] $(1): not implemented yet — see make/generic.mk  # TODO(template)"
endef

lang-setup:
	$(call _todo,setup)

lang-lint:
	$(call _todo,lint)

lang-format:
	$(call _todo,format)

lang-test:
	$(call _todo,test)

lang-test-integration:
	$(call _todo,integration test)

lang-fuzz:
	$(call _todo,fuzz)

lang-audit:
	$(call _todo,audit)

lang-build:
	@mkdir -p $(DIST_DIR)
	$(call _todo,build)

lang-clean:
	@true
