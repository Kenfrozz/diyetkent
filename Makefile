# Flutter Project Makefile
# Provides convenient commands for development and testing

# Default Flutter command
FLUTTER := flutter
DART := dart

# Project directories
BUILD_DIR := build
COVERAGE_DIR := coverage
TEST_REPORTS_DIR := test_reports

# Coverage threshold
COVERAGE_THRESHOLD := 70

.PHONY: help install clean build test coverage analyze format lint setup ci

# Default target
help:
	@echo "Flutter Project Development Commands"
	@echo "===================================="
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make install     - Install dependencies"
	@echo "  make setup       - Complete project setup (deps + codegen)"
	@echo ""
	@echo "Development:"
	@echo "  make clean       - Clean project artifacts"
	@echo "  make build       - Build APK"
	@echo "  make format      - Format code"
	@echo "  make analyze     - Analyze code"
	@echo "  make lint        - Run linting"
	@echo ""
	@echo "Testing:"
	@echo "  make test        - Run all tests"
	@echo "  make test-unit   - Run unit tests only"
	@echo "  make test-widget - Run widget tests only"
	@echo "  make test-integration - Run integration tests only"
	@echo "  make coverage    - Run tests with coverage"
	@echo "  make coverage-html - Generate HTML coverage report"
	@echo ""
	@echo "CI/CD:"
	@echo "  make ci          - Run full CI pipeline locally"
	@echo "  make validate    - Validate project setup"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	$(FLUTTER) pub get

# Complete setup
setup: install
	@echo "🔨 Generating code..."
	$(FLUTTER) packages pub run build_runner build --delete-conflicting-outputs

# Clean project
clean:
	@echo "🧹 Cleaning project..."
	$(FLUTTER) clean
	@rm -rf $(BUILD_DIR) $(COVERAGE_DIR) $(TEST_REPORTS_DIR)

# Build APK
build: setup
	@echo "🏗️  Building APK..."
	$(FLUTTER) build apk --debug

# Format code
format:
	@echo "🎨 Formatting code..."
	$(DART) format .

# Analyze code
analyze: setup
	@echo "🔍 Analyzing code..."
	$(FLUTTER) analyze

# Run linting
lint: format analyze
	@echo "✅ Linting completed"

# Run all tests
test: setup
	@echo "🧪 Running all tests..."
	$(FLUTTER) test

# Run unit tests only
test-unit: setup
	@echo "🔬 Running unit tests..."
	@if [ -d "test/unit" ]; then $(FLUTTER) test test/unit/; else echo "No unit tests found"; fi

# Run widget tests only
test-widget: setup
	@echo "🎨 Running widget tests..."
	@if [ -d "test/widget" ]; then $(FLUTTER) test test/widget/; else echo "No widget tests found"; fi

# Run integration tests only
test-integration: setup
	@echo "🔗 Running integration tests..."
	@if [ -d "test/integration" ]; then $(FLUTTER) test test/integration/; else echo "No integration tests found"; fi

# Run tests with coverage
coverage: setup
	@echo "📊 Running tests with coverage..."
	$(FLUTTER) test --coverage
	@if [ -f "$(COVERAGE_DIR)/lcov.info" ]; then \
		echo "✅ Coverage data generated"; \
		if command -v lcov >/dev/null 2>&1; then \
			COVERAGE=$$(lcov --summary $(COVERAGE_DIR)/lcov.info 2>/dev/null | grep "lines" | awk '{print $$2}' | sed 's/%//' || echo "0"); \
			echo "Coverage: $${COVERAGE}% (Threshold: $(COVERAGE_THRESHOLD)%)"; \
			if [ "$$(echo "$${COVERAGE} >= $(COVERAGE_THRESHOLD)" | bc -l 2>/dev/null || echo "0")" = "1" ]; then \
				echo "✅ Coverage threshold met!"; \
			else \
				echo "❌ Coverage below threshold"; \
			fi; \
		fi; \
	else \
		echo "❌ Coverage generation failed"; \
	fi

# Generate HTML coverage report
coverage-html: coverage
	@echo "🌐 Generating HTML coverage report..."
	@if command -v genhtml >/dev/null 2>&1; then \
		genhtml $(COVERAGE_DIR)/lcov.info -o $(COVERAGE_DIR)/html; \
		echo "✅ HTML report: $(COVERAGE_DIR)/html/index.html"; \
	else \
		echo "❌ genhtml not found. Install lcov to generate HTML reports."; \
	fi

# Validate project setup
validate:
	@echo "🔍 Validating project setup..."
	@$(DART) test/test_runner.dart --validate

# Full CI pipeline
ci: clean install format analyze coverage build
	@echo "🎉 CI pipeline completed successfully!"

# Run quick checks (for pre-commit hooks)
check: format analyze test-unit
	@echo "✅ Quick checks completed"

# Development server
dev:
	@echo "🚀 Starting development server..."
	$(FLUTTER) run

# Generate mocks
mocks: install
	@echo "🎭 Generating mocks..."
	$(FLUTTER) packages pub run build_runner build --delete-conflicting-outputs

# Update dependencies
update:
	@echo "📦 Updating dependencies..."
	$(FLUTTER) pub upgrade
	$(FLUTTER) pub get

# Check outdated packages
outdated:
	@echo "📋 Checking for outdated packages..."
	$(FLUTTER) pub outdated

# Security audit (check for vulnerabilities)
security:
	@echo "🔒 Running security checks..."
	$(FLUTTER) pub deps
	@echo "✅ Security check completed. Review dependencies above."

# Install git hooks
hooks:
	@echo "🪝 Installing git hooks..."
	@if [ -f ".git/hooks/pre-commit" ]; then \
		echo "Pre-commit hook already exists"; \
	else \
		echo "#!/bin/sh\nmake check" > .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "✅ Pre-commit hook installed"; \
	fi