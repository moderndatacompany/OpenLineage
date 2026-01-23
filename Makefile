# OpenLineage Development Makefile
# 
# This project uses path-based dependencies instead of a UV workspace
# Each integration is now a standalone project with isolated dependencies

.PHONY: help setup-* test-* lint-* clean java-* python-*

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
CYAN := \033[36m
BOLD := \033[1m
DIM := \033[2m
NC := \033[0m # No Color

# Project info
PROJECT_NAME := OpenLineage
JAVA_GROUP_ID := io.dataos.openlineage
JAVA_ARTIFACT_ID := openlineage-java
PYTHON_PACKAGE_NAME := dataos-openlineage-python

help: ## Show this help message
	@echo ""
	@echo "$(BOLD)$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BOLD)$(BLUE)  $(PROJECT_NAME) - Development Toolchain (DataOS Fork)$(NC)"
	@echo "$(BOLD)$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(BOLD)USAGE:$(NC)"
	@echo "    make $(CYAN)<command>$(NC)"
	@echo ""
	@echo "$(BOLD)JAVA CLIENT COMMANDS:$(NC)"
	@echo "    $(GREEN)java-info$(NC)             Show version and artifact coordinates"
	@echo "    $(GREEN)java-build$(NC)            Build and test Java client JAR (requires Docker)"
	@echo "    $(GREEN)java-build-quick$(NC)      Build Java client, skip Docker-dependent tests"
	@echo "    $(GREEN)java-publish-local$(NC)    Publish to local Maven (~/.m2/repository)"
	@echo "    $(GREEN)java-publish-github$(NC)   Publish to GitHub Packages"
	@echo "    $(GREEN)java-publish$(NC)          Publish to Maven Central (requires credentials)"
	@echo ""
	@echo "$(BOLD)PYTHON CLIENT COMMANDS:$(NC)"
	@echo "    $(GREEN)python-info$(NC)           Show version and package info"
	@echo "    $(GREEN)python-build$(NC)          Build Python wheel and sdist"
	@echo "    $(GREEN)python-test$(NC)           Run Python client tests"
	@echo "    $(GREEN)python-publish-local$(NC)  Install locally for testing"
	@echo "    $(GREEN)python-publish$(NC)        Publish to PyPI (requires credentials)"
	@echo ""
	@echo "$(BOLD)PYTHON SETUP COMMANDS:$(NC)"
	@echo "    $(GREEN)setup-client$(NC)          Setup Python client dependencies"
	@echo "    $(GREEN)setup-common$(NC)          Setup integration common library"
	@echo "    $(GREEN)setup-dbt$(NC)             Setup dbt integration"
	@echo "    $(GREEN)test-client$(NC)           Run Python client tests"
	@echo "    $(GREEN)test-common$(NC)           Run integration common tests"
	@echo "    $(GREEN)test-dbt$(NC)              Run dbt integration tests"
	@echo "    $(GREEN)test-all$(NC)              Run all Python tests"
	@echo ""
	@echo "$(BOLD)CODE QUALITY:$(NC)"
	@echo "    $(GREEN)lint-all$(NC)              Run all linting and type checking"
	@echo "    $(GREEN)lint-format$(NC)           Run ruff formatting checks"
	@echo "    $(GREEN)lint-types$(NC)            Run mypy type checking"
	@echo "    $(GREEN)fix-format$(NC)            Auto-fix formatting issues"
	@echo ""
	@echo "$(BOLD)UTILITY:$(NC)"
	@echo "    $(GREEN)status$(NC)                Show build status of all components"
	@echo "    $(GREEN)clean$(NC)                 Clean all build artifacts and caches"
	@echo "    $(GREEN)ci-test$(NC)               Run full CI simulation locally"
	@echo ""
	@echo "$(BOLD)EXAMPLES:$(NC)"
	@echo "    $(DIM)# Build Java client and run tests$(NC)"
	@echo "    make java-build"
	@echo ""
	@echo "    $(DIM)# Publish to local Maven for testing in other projects$(NC)"
	@echo "    make java-publish-local"
	@echo ""
	@echo "    $(DIM)# Then use in your project:$(NC)"
	@echo "    $(DIM)# Maven:  $(JAVA_GROUP_ID):$(JAVA_ARTIFACT_ID):<version>$(NC)"
	@echo "    $(DIM)# Gradle: implementation '$(JAVA_GROUP_ID):$(JAVA_ARTIFACT_ID):<version>'$(NC)"
	@echo ""
	@echo "    $(DIM)# Publish to Maven Central (requires credentials)$(NC)"
	@echo "    export RELEASE_USERNAME=your_username"
	@echo "    export RELEASE_PASSWORD=your_password"
	@echo "    make java-publish"
	@echo ""
	@echo "$(BOLD)ENVIRONMENT VARIABLES:$(NC)"
	@echo "    $(YELLOW)RELEASE_USERNAME$(NC)      Sonatype/Maven Central username (for java-publish)"
	@echo "    $(YELLOW)RELEASE_PASSWORD$(NC)      Sonatype/Maven Central password (for java-publish)"
	@echo "    $(YELLOW)TWINE_USERNAME$(NC)        PyPI username (for python-publish)"
	@echo "    $(YELLOW)TWINE_PASSWORD$(NC)        PyPI token (for python-publish)"
	@echo ""
	@echo "$(BOLD)ARTIFACT INFO:$(NC)"
	@echo "  $(BOLD)Java:$(NC)"
	@echo "    Group ID:     $(CYAN)$(JAVA_GROUP_ID)$(NC)"
	@echo "    Artifact ID:  $(CYAN)$(JAVA_ARTIFACT_ID)$(NC)"
	@echo "    JAR Location: $(CYAN)client/java/build/libs/$(NC)"
	@echo "  $(BOLD)Python:$(NC)"
	@echo "    Package:      $(CYAN)$(PYTHON_PACKAGE_NAME)$(NC)"
	@echo "    Wheel:        $(CYAN)client/python/dist/$(NC)"
	@echo ""
	@echo "$(DIM)Run 'make java-info' or 'make python-info' for detailed version info$(NC)"
	@echo ""

# =============================================================================
# Setup Commands - Install dependencies for specific integrations
# =============================================================================

setup-client: ## Setup Python client
	@echo "$(BLUE)Setting up Python client...$(NC)"
	cd client/python && uv sync --extra test --extra dev --extra generator --extra kafka --extra msk-iam --extra datazone --extra fsspec --active

setup-common: ## Setup integration common library
	@echo "$(BLUE)Setting up integration common...$(NC)"
	cd integration/common && uv sync --extra dev --active

setup-dbt: ## Setup dbt integration
	@echo "$(BLUE)Setting up dbt integration...$(NC)"
	cd integration/dbt && uv sync --extra dev --active

# =============================================================================
# Testing Commands
# =============================================================================

test-all: ## Run all tests
	@echo "$(BLUE)Running all tests...$(NC)"
	@$(MAKE) test-client
	@$(MAKE) test-common
	@$(MAKE) test-dbt
	@echo "$(GREEN)✅ All tests completed!$(NC)"

test-client: ## Test Python client
	@echo "$(BLUE)Testing Python client...$(NC)"
	@$(MAKE) setup-client
	cd client/python && uv run pytest tests/

test-common: ## Test integration common library
	@echo "$(BLUE)Testing integration common...$(NC)"
	@$(MAKE) setup-common
	cd integration/common && uv run pytest tests/

test-dbt: ## Test dbt integration
	@echo "$(BLUE)Testing dbt integration...$(NC)"
	@$(MAKE) setup-dbt
	cd integration/dbt && uv run pytest tests/

# =============================================================================
# Linting & Formatting
# =============================================================================

lint-all: ## Run all linting and type checking
	@echo "$(BLUE)Running linting and type checking...$(NC)"
	@$(MAKE) lint-format
	@$(MAKE) lint-types
	@echo "$(GREEN)✅ All linting completed!$(NC)"

lint-format: ## Run ruff formatting and linting
	@echo "$(BLUE)Running ruff checks...$(NC)"
	uv tool run ruff check .
	uv tool run ruff format --check .

lint-types: ## Run mypy type checking per integration
	@echo "$(BLUE)Running mypy type checking...$(NC)"
	cd client/python && uv run mypy src/
	cd integration/common && uv run mypy src/
	cd integration/dbt && uv run mypy src/ --ignore-missing-imports

fix-format: ## Auto-fix formatting issues
	@echo "$(BLUE)Auto-fixing format issues...$(NC)"
	uv tool run ruff format .
	uv tool run ruff check --fix .

# =============================================================================
# Java Client Commands
# =============================================================================

java-info: ## Show Java client version and artifact info
	@echo ""
	@echo "$(BOLD)$(BLUE)Java Client Artifact Info$(NC)"
	@echo "$(BLUE)─────────────────────────────────────────────────────$(NC)"
	@VERSION=$$(grep "^version=" client/java/gradle.properties | cut -d'=' -f2); \
	GROUP_ID=$$(grep "^groupId=" client/java/gradle.properties | cut -d'=' -f2); \
	ARTIFACT_ID=$$(grep "^artifactId=" client/java/gradle.properties | cut -d'=' -f2); \
	echo "  $(BOLD)Group ID:$(NC)     $(CYAN)$$GROUP_ID$(NC)"; \
	echo "  $(BOLD)Artifact ID:$(NC)  $(CYAN)$$ARTIFACT_ID$(NC)"; \
	echo "  $(BOLD)Version:$(NC)      $(CYAN)$$VERSION$(NC)"; \
	echo ""; \
	echo "  $(BOLD)Maven:$(NC)"; \
	echo "    $(DIM)<dependency>$(NC)"; \
	echo "    $(DIM)  <groupId>$(NC)$$GROUP_ID$(DIM)</groupId>$(NC)"; \
	echo "    $(DIM)  <artifactId>$(NC)$$ARTIFACT_ID$(DIM)</artifactId>$(NC)"; \
	echo "    $(DIM)  <version>$(NC)$$VERSION$(DIM)</version>$(NC)"; \
	echo "    $(DIM)</dependency>$(NC)"; \
	echo ""; \
	echo "  $(BOLD)Gradle:$(NC)"; \
	echo "    implementation '$$GROUP_ID:$$ARTIFACT_ID:$$VERSION'"; \
	echo ""; \
	if echo "$$VERSION" | grep -q "SNAPSHOT"; then \
		echo "  $(YELLOW)⚠ SNAPSHOT version - signing not required$(NC)"; \
	else \
		echo "  $(GREEN)✓ Release version - GPG signing required$(NC)"; \
	fi
	@echo ""

java-build: ## Build and test Java client JAR (requires Docker for transport tests)
	@echo "$(BLUE)Building Java client...$(NC)"
	cd client/java && ./gradlew --console=plain build
	@echo "$(GREEN)✅ Java client built successfully!$(NC)"
	@echo "JAR location: client/java/build/libs/"

java-build-quick: ## Build Java client, skip tests that require Docker
	@echo "$(BLUE)Building Java client (skipping Docker-dependent tests)...$(NC)"
	cd client/java && ./gradlew --console=plain build -x :transports-s3:test -x :transports-gcs:test -x :transports-kinesis:test -x :transports-gcplineage:test -x :transports-datazone:test
	@echo "$(GREEN)✅ Java client built successfully!$(NC)"
	@echo "JAR location: client/java/build/libs/"
	@echo "$(YELLOW)Note: Transport module tests were skipped (require Docker)$(NC)"

java-publish-local: ## Publish Java client to local Maven (~/.m2/repository)
	@echo "$(BLUE)Publishing Java client to local Maven repository...$(NC)"
	cd client/java && ./gradlew --console=plain publishToMavenLocal
	@echo "$(GREEN)✅ Published to local Maven!$(NC)"
	@echo "Artifact: $(JAVA_GROUP_ID):$(JAVA_ARTIFACT_ID)"
	@echo "Location: ~/.m2/repository/io/dataos/openlineage/$(JAVA_ARTIFACT_ID)/"

java-publish: ## Publish Java client to Maven Central (requires credentials)
	@echo "$(BLUE)Publishing Java client to Maven Central...$(NC)"
	@if [ -z "$$RELEASE_USERNAME" ] || [ -z "$$RELEASE_PASSWORD" ]; then \
		echo "$(RED)❌ Error: RELEASE_USERNAME and RELEASE_PASSWORD must be set$(NC)"; \
		echo "Export these environment variables before running this command."; \
		exit 1; \
	fi
	cd client/java && ./gradlew --console=plain :publishToSonatype :closeAndReleaseSonatypeStagingRepository
	@echo "$(GREEN)✅ Published to Maven Central!$(NC)"

# =============================================================================
# Python Client Commands
# =============================================================================

python-info: ## Show Python client version and package info
	@echo ""
	@echo "$(BOLD)$(BLUE)Python Client Package Info$(NC)"
	@echo "$(BLUE)─────────────────────────────────────────────────────$(NC)"
	@VERSION=$$(grep "^version = " client/python/pyproject.toml | head -1 | cut -d'"' -f2); \
	NAME=$$(grep "^name = " client/python/pyproject.toml | head -1 | cut -d'"' -f2); \
	echo "  $(BOLD)Package:$(NC)  $(CYAN)$$NAME$(NC)"; \
	echo "  $(BOLD)Version:$(NC)  $(CYAN)$$VERSION$(NC)"; \
	echo ""; \
	echo "  $(BOLD)Install:$(NC)"; \
	echo "    pip install $$NAME==$$VERSION"; \
	echo ""; \
	echo "  $(BOLD)Requirements.txt:$(NC)"; \
	echo "    $$NAME==$$VERSION"; \
	echo ""; \
	echo "  $(BOLD)With extras:$(NC)"; \
	echo "    pip install \"$$NAME[kafka]==$$VERSION\""; \
	echo ""

python-build: ## Build Python wheel and source distribution
	@echo "$(BLUE)Building Python client...$(NC)"
	cd client/python && uv build
	@echo "$(GREEN)✅ Python client built successfully!$(NC)"
	@echo "Wheel location: client/python/dist/"
	@ls -la client/python/dist/ 2>/dev/null || echo "$(YELLOW)Run the command to see dist contents$(NC)"

python-test: ## Run Python client tests
	@echo "$(BLUE)Running Python client tests...$(NC)"
	cd client/python && uv sync --extra test --extra dev
	cd client/python && uv run pytest tests/
	@echo "$(GREEN)✅ Python tests completed!$(NC)"

python-publish-local: ## Install Python client locally for testing
	@echo "$(BLUE)Installing Python client locally...$(NC)"
	cd client/python && uv build
	cd client/python && pip install dist/*.whl --force-reinstall
	@echo "$(GREEN)✅ Installed locally!$(NC)"
	@echo "Test with: python -c \"from openlineage.client import __version__; print(__version__)\""

python-publish: ## Publish Python client to PyPI (requires credentials)
	@echo "$(BLUE)Publishing Python client to PyPI...$(NC)"
	@if [ -z "$$TWINE_USERNAME" ] || [ -z "$$TWINE_PASSWORD" ]; then \
		echo "$(RED)❌ Error: TWINE_USERNAME and TWINE_PASSWORD must be set$(NC)"; \
		echo "Export these environment variables:"; \
		echo "  export TWINE_USERNAME=__token__"; \
		echo "  export TWINE_PASSWORD=pypi-xxxxxx"; \
		exit 1; \
	fi
	cd client/python && uv build
	pip install twine
	twine upload client/python/dist/*
	@echo "$(GREEN)✅ Published to PyPI!$(NC)"
	@echo "Install with: pip install $(PYTHON_PACKAGE_NAME)"

# =============================================================================
# Development Shortcuts
# =============================================================================

dbt: ## Enter dbt integration directory
	@echo "$(GREEN)🔧 Switching to dbt integration$(NC)"
	@echo "Run: cd integration/dbt && uv sync --extra tests"
	@cd integration/dbt && bash

client: ## Enter Python client directory
	@echo "$(GREEN)🐍 Switching to Python client$(NC)"
	@echo "Run: cd client/python && uv sync --extra tests"
	@cd client/python && bash

# =============================================================================
# Status & Information
# =============================================================================

status: ## Show status of all integrations
	@echo "$(BLUE)Integration Status:$(NC)"
	@echo -n "Client Python: "; \
	if [ -d "client/python/.venv" ]; then echo "$(GREEN)✅ Ready$(NC)"; else echo "$(RED)❌ Not setup$(NC)"; fi
	@echo -n "Client Java: "; \
	if [ -d "client/java/build/libs" ]; then echo "$(GREEN)✅ Built$(NC)"; else echo "$(YELLOW)⚠ Not built$(NC)"; fi
	@echo -n "Common: "; \
	if [ -d "integration/common/.venv" ]; then echo "$(GREEN)✅ Ready$(NC)"; else echo "$(RED)❌ Not setup$(NC)"; fi
	@echo -n "dbt: "; \
	if [ -d "integration/dbt/.venv" ]; then echo "$(GREEN)✅ Ready$(NC)"; else echo "$(RED)❌ Not setup$(NC)"; fi

# =============================================================================
# Utility Commands
# =============================================================================

clean: ## Clean all virtual environments and caches
	@echo "$(YELLOW)Cleaning virtual environments and caches...$(NC)"
	rm -rf client/python/.venv
	rm -rf client/python/dist
	rm -rf client/python/*.egg-info
	rm -rf integration/common/.venv
	rm -rf integration/dbt/.venv
	uv cache clean
	@echo "$(YELLOW)Cleaning Java build artifacts...$(NC)"
	cd client/java && ./gradlew --console=plain clean
	rm -rf client/java/build-cache
	@echo "$(GREEN)✅ Cleanup completed!$(NC)"

# =============================================================================
# CI Simulation
# =============================================================================

ci-test: ## Run the same checks that CI runs
	@echo "$(BLUE)Running CI simulation...$(NC)"
	@$(MAKE) lint-all
	@$(MAKE) test-all
	@echo "$(GREEN)✅ All CI checks passed!$(NC)"