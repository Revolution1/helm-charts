.PHONY: help lint package clean

CHART_DIRS := $(shell find charts -mindepth 1 -maxdepth 1 -type d)
HELM := helm

help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

lint: ## Lint all charts using ct (chart-testing)
	@echo "Linting charts..."
	ct lint --config .ct.yaml --all

lint-helm: ## Lint all charts using helm lint
	@echo "Linting charts with helm..."
	@for dir in $(CHART_DIRS); do \
		echo "Linting $$dir..."; \
		$(HELM) lint $$dir; \
	done

package: ## Package all charts
	@echo "Packaging charts..."
	@mkdir -p .cr-release-packages
	@for dir in $(CHART_DIRS); do \
		echo "Packaging $$dir..."; \
		$(HELM) package $$dir -d .cr-release-packages; \
	done

clean: ## Clean up packaged charts
	@echo "Cleaning up..."
	@rm -rf .cr-release-packages
	@rm -rf .cr-index

deps: ## Update chart dependencies
	@echo "Updating chart dependencies..."
	@for dir in $(CHART_DIRS); do \
		if [ -f "$$dir/Chart.yaml" ]; then \
			echo "Updating dependencies for $$dir..."; \
			$(HELM) dependency update $$dir; \
		fi \
	done

docs: ## Generate documentation for charts
	@echo "Generating chart documentation..."
	@for dir in $(CHART_DIRS); do \
		if [ -f "$$dir/Chart.yaml" ]; then \
			echo "Generating docs for $$dir..."; \
			$(HELM) show all $$dir > $$dir/README.md.tmp || true; \
		fi \
	done

template: ## Run helm template on all charts
	@echo "Running helm template on charts..."
	@for dir in $(CHART_DIRS); do \
		echo "Templating $$dir..."; \
		$(HELM) template test $$dir > /dev/null; \
	done
