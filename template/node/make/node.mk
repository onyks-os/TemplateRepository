# ---------------------------------------------------------------------------
# node.mk — Node/TypeScript implementation of the lang-* target contract.
# ---------------------------------------------------------------------------

NPM ?= npm

.PHONY: lang-setup lang-lint lang-format lang-test lang-test-integration lang-fuzz lang-audit lang-build lang-clean coverage dev

lang-setup:
	@echo "==> [$(PROJECT_SHORT)] Installing npm dependencies..."
	@$(NPM) ci || $(NPM) install

lang-lint:
	@echo "==> [$(PROJECT_SHORT)] Type checking..."
	@$(NPM) run typecheck
	@echo "==> [$(PROJECT_SHORT)] ESLint + Prettier..."
	@$(NPM) run lint

lang-format:
	@echo "==> [$(PROJECT_SHORT)] Auto-formatting..."
	@$(NPM) run lint:fix

lang-test:
	@echo "==> [$(PROJECT_SHORT)] Unit tests..."
	@$(NPM) test

lang-test-integration:
	@echo "==> [$(PROJECT_SHORT)] Integration tests..."
	@$(NPM) run test -- --run tests/integration

lang-fuzz:
	@echo "==> [$(PROJECT_SHORT)] Property-based tests (fast-check)..."
	@$(NPM) run test -- --run tests/properties

lang-audit:
	@echo "==> [$(PROJECT_SHORT)] npm audit..."
	@$(NPM) audit --audit-level=high

lang-build:
	@echo "==> [$(PROJECT_SHORT)] Building..."
	@$(NPM) run build
	@mkdir -p $(DIST_DIR) && $(NPM) pack --pack-destination $(DIST_DIR)

lang-clean:
	@rm -rf node_modules/.cache coverage/ *.tsbuildinfo

##@ Node extras

coverage: ## Run the test suite with a coverage report
	@$(NPM) run test:coverage

dev: ## Start the development server / watcher
	@$(NPM) run test:watch
