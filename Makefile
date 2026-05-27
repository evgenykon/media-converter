.PHONY: setup analyze test clean run build format outdated upgrade doctor

setup: ## Install dependencies and generate code
	flutter pub get

analyze: ## Run the Dart analyzer
	flutter analyze

test: ## Run all tests
	flutter test

clean: ## Clean build artifacts and dependencies
	flutter clean
	flutter pub cache clean

run: ## Run on connected device
	flutter run

build: ## Build for a specific platform (usage: make build platform=apk|ios|web|macos|linux|windows)
	flutter build $(platform)

format: ## Format Dart source code
	dart format lib/ test/

outdated: ## Check for outdated dependencies
	flutter pub outdated

upgrade: ## Upgrade to the latest compatible dependencies
	flutter pub upgrade

doctor: ## Check Flutter installation status
	flutter doctor
