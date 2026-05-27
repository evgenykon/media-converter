.PHONY: setup analyze test clean purge run build format outdated upgrade doctor

setup: ## Install dependencies and generate code
	flutter pub get

analyze: ## Run the Dart analyzer
	flutter analyze

test: ## Run all tests
	flutter test

clean: ## Clean build artifacts and dependencies
	flutter clean
	flutter pub cache clean

purge: ## Clean garbage: derived data, caches, build artifacts
	flutter clean
	rm -rf .dart_tool/
	rm -rf build/
	rm -rf macos/Pods/
	rm -rf windows/runner/cmake-build*/
	rm -rf macos/Runner.xcworkspace/xcuserdata/
	rm -rf ~/Library/Caches/com.flutter.*
	rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
	flutter pub cache clean

run: ## Run on macOS
	flutter run -d macos

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
