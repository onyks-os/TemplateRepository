# ---------------------------------------------------------------------------
# rust.mk — Rust implementation of the lang-* target contract.
# ---------------------------------------------------------------------------

CARGO ?= cargo

.PHONY: lang-setup lang-lint lang-format lang-test lang-test-integration lang-fuzz lang-audit lang-build lang-clean coverage doc

lang-setup:
	@echo "==> [$(PROJECT_SHORT)] Installing toolchain components..."
	@rustup component add clippy rustfmt 2>/dev/null || true
	@$(CARGO) fetch

lang-lint:
	@echo "==> [$(PROJECT_SHORT)] rustfmt check..."
	@$(CARGO) fmt --all -- --check
	@echo "==> [$(PROJECT_SHORT)] Clippy (warnings are errors)..."
	@$(CARGO) clippy --all-targets --all-features -- -D warnings

lang-format:
	@echo "==> [$(PROJECT_SHORT)] Auto-formatting..."
	@$(CARGO) fmt --all
	@$(CARGO) clippy --all-targets --all-features --fix --allow-dirty --allow-staged || true

lang-test:
	@echo "==> [$(PROJECT_SHORT)] Unit tests..."
	@$(CARGO) test --all-features

lang-test-integration:
	@echo "==> [$(PROJECT_SHORT)] Integration tests..."
	@$(CARGO) test --all-features --test '*' -- --ignored

lang-fuzz:
	@echo "==> [$(PROJECT_SHORT)] Property-based tests (proptest)..."
	@PROPTEST_CASES=$${PROPTEST_CASES:-1024} $(CARGO) test --all-features properties

lang-audit:
	@echo "==> [$(PROJECT_SHORT)] cargo-audit..."
	@if command -v cargo-audit >/dev/null 2>&1; then \
		$(CARGO) audit; \
	else \
		echo "==> cargo-audit not found. Install: cargo install cargo-audit"; exit 1; \
	fi

lang-build:
	@echo "==> [$(PROJECT_SHORT)] Building release binary..."
	@$(CARGO) build --release
	@mkdir -p $(DIST_DIR)
	@cp target/release/$(PROJECT_DIST) $(DIST_DIR)/ 2>/dev/null || true
	@$(CARGO) package --allow-dirty --target-dir target/package >/dev/null 2>&1 || true
	@cp target/package/package/*.crate $(DIST_DIR)/ 2>/dev/null || true

lang-clean:
	@$(CARGO) clean

##@ Rust extras

coverage: ## Run the test suite with a coverage report (cargo-llvm-cov)
	@$(CARGO) llvm-cov --all-features --workspace --html

doc: ## Build and open the rustdoc API documentation
	@$(CARGO) doc --no-deps --all-features --open
