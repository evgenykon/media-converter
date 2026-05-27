# Media Converter

A Flutter application for media conversion.

## Tech Stack

- **Framework:** Flutter (SDK `^3.12.0`)
- **Language:** Dart
- **Linting:** `flutter_lints ^6.0.0` (standard Flutter lint rules)
- **Platforms:** macOS, Windows

## Project Structure

```
lib/
  main.dart                    # App entry point, MaterialApp, counter demo

test/
  widget_test.dart             # Default widget smoke test
```

## Current State

Freshly scaffolded Flutter project — the default counter demo app. No custom architecture, no additional dependencies beyond `cupertino_icons`. The `lib/` directory is flat; organize by feature or layer as the app grows.

## Conventions

- Use `flutter analyze` to check for lint errors before committing.
- Use `flutter test` to run all tests.
- Do not add comments unless they explain non-obvious logic.
- Follow standard Flutter/Dart conventions from `package:flutter_lints`.
- Match existing code style when editing.

## Build Commands

| Command | Description |
|---|---|
| `make setup` | Install dependencies |
| `make analyze` | Run the Dart analyzer |
| `make test` | Run all tests |
| `make clean` | Clean build artifacts and cache |
| `make purge` | Clean garbage: derived data, .dart_tool, Pods, Xcode caches |
| `make run` | Build and launch on macOS |
| `make release VERSION=x.y.z` | Build release version and create ZIP archive |
| `make build platform=<target>` | Build for a specific platform |
| `make format` | Format Dart source code |
| `make outdated` | Check for outdated dependencies |
| `make upgrade` | Upgrade dependencies |
| `make doctor` | Check Flutter installation status |
