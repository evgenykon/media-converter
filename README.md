# Media Converter

A Flutter application for media conversion.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.12.0`
- Platform-specific toolchains (Xcode for iOS/macOS, Android Studio for Android, etc.)

### Setup

```bash
flutter pub get
```

## Makefile Commands

| Command | Description |
|---|---|
| `make setup` | Install dependencies |
| `make analyze` | Run the Dart analyzer |
| `make test` | Run all tests |
| `make clean` | Clean build artifacts and cache |
| `make run` | Run on connected device |
| `make build platform=<target>` | Build for a platform (`apk`, `ios`, `web`, `macos`, `linux`, `windows`) |
| `make format` | Format Dart source code |
| `make outdated` | Check for outdated dependencies |
| `make upgrade` | Upgrade dependencies |
| `make doctor` | Check Flutter installation status |

## Building

```bash
# macOS
make build platform=macos

# Windows
make build platform=windows
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
