.PHONY: test test-lib test-widgets test-all help install-deps check-bats

RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

TEST_DIR := test
LIB_TEST_DIR := $(TEST_DIR)/lib
WIDGET_TEST_DIR := $(TEST_DIR)/widgets

LIB_TESTS := $(wildcard $(LIB_TEST_DIR)/*.bats)
WIDGET_TESTS := $(wildcard $(WIDGET_TEST_DIR)/*.bats)
ALL_TESTS := $(LIB_TESTS) $(WIDGET_TESTS)

help: ## Show this help message
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

install-deps: ## Install required dependencies (bats-core)
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing bats-core...$(NC)"; \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install bats-core || echo "$(RED)Error: Could not install bats-core. Install manually: brew install bats-core$(NC)"; \
		else \
			echo "$(RED)Please install bats-core manually:$(NC)"; \
			echo "  Ubuntu/Debian: sudo apt-get install bats"; \
			echo "  Fedora/RHEL: sudo yum install bats"; \
			echo "  Or follow: https://github.com/bats-core/bats-core"; \
		fi \
	else \
		echo "$(GREEN)bats-core is already installed$(NC)"; \
	fi

check-bats: ## Check if bats is installed
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "$(RED)Error: bats is not installed$(NC)"; \
		echo "Run: make install-deps"; \
		exit 1; \
	fi
	@echo "$(GREEN)bats is installed$(NC)"

test: check-bats ## Run all tests
	@echo "$(GREEN)Running all tests...$(NC)"
	@echo ""
	@bats $(ALL_TESTS)

test-lib: check-bats ## Run only library tests
	@echo "$(GREEN)Running library tests...$(NC)"
	@echo ""
	@bats $(LIB_TESTS)

test-widgets: check-bats ## Run only widget tests
	@echo "$(GREEN)Running widget tests...$(NC)"
	@echo ""
	@bats $(WIDGET_TESTS)

test-all: test ## Alias for test (runs all tests)

test-cache: check-bats ## Run cache tests
	@bats $(LIB_TEST_DIR)/cache.bats

test-color-scale: check-bats ## Run color-scale tests
	@bats $(LIB_TEST_DIR)/color-scale.bats

test-command-timeout: check-bats ## Run command-timeout tests
	@bats $(LIB_TEST_DIR)/command-timeout.bats

test-conditional-display: check-bats ## Run conditional-display tests
	@bats $(LIB_TEST_DIR)/conditional-display.bats

test-config-validator: check-bats ## Run config-validator tests
	@bats $(LIB_TEST_DIR)/config-validator.bats

test-constants: check-bats ## Run constants tests
	@bats $(LIB_TEST_DIR)/constants.bats

test-coreutils: check-bats ## Run coreutils-compat tests
	@bats $(LIB_TEST_DIR)/coreutils-compat.bats

test-format: check-bats ## Run format tests
	@bats $(LIB_TEST_DIR)/format.bats

test-git: check-bats ## Run git tests
	@bats $(LIB_TEST_DIR)/git.bats

test-network-utils: check-bats ## Run network-utils tests
	@bats $(LIB_TEST_DIR)/network-utils.bats

test-platform: check-bats ## Run platform-detector tests
	@bats $(LIB_TEST_DIR)/platform-detector.bats

test-system: check-bats ## Run system tests
	@bats $(LIB_TEST_DIR)/system.bats

test-themes: check-bats ## Run themes tests
	@bats $(LIB_TEST_DIR)/themes.bats

test-retry: check-bats ## Run retry tests
	@bats $(LIB_TEST_DIR)/retry.bats

test-tmux-config: check-bats ## Run tmux-config tests
	@bats $(LIB_TEST_DIR)/tmux-config.bats

test-ui: check-bats ## Run ui tests
	@bats $(LIB_TEST_DIR)/ui.bats

test-widget-base: check-bats ## Run widget-base tests
	@bats $(LIB_TEST_DIR)/widget-base.bats

test-context-widget: check-bats ## Run context-widget tests
	@bats $(WIDGET_TEST_DIR)/context-widget.bats

test-git-widget: check-bats ## Run git-widget tests
	@bats $(WIDGET_TEST_DIR)/git-widget.bats

test-network-widget: check-bats ## Run network-widget tests
	@bats $(WIDGET_TEST_DIR)/network-widget.bats

test-system-widget: check-bats ## Run system-widget tests
	@bats $(WIDGET_TEST_DIR)/system-widget.bats

test-verbose: check-bats ## Run tests with detailed output (TAP)
	@bats --tap $(ALL_TESTS)

test-list: ## List all test files
	@echo "$(GREEN)Library tests:$(NC)"
	@for test in $(LIB_TESTS); do echo "  - $$test"; done
	@echo ""
	@echo "$(GREEN)Widget tests:$(NC)"
	@for test in $(WIDGET_TESTS); do echo "  - $$test"; done
	@echo ""
	@echo "$(GREEN)Total: $(words $(ALL_TESTS)) test files$(NC)"

clean: ## Clean temporary test files
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@rm -rf /tmp/tmux_tokyo_night_cache
	@rm -rf /tmp/tmux_tokyo_night_weather_cache
	@rm -rf /tmp/tmux_tokyo_night_ping_cache
	@echo "$(GREEN)Cleanup complete$(NC)"

benchmark: ## Run performance benchmarks
	@echo "$(GREEN)Running benchmarks...$(NC)"
	@bash scripts/benchmark.sh

check-deps: ## Check dependencies
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@bash scripts/check-dependencies.sh

install-hooks: ## Install pre-commit hooks
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@bash scripts/install-hooks.sh

.DEFAULT_GOAL := help
