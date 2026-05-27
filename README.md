# Media Converter

Desktop tool for video/audio conversion using FFmpeg, with YouTube download support.

## Dependencies

The app requires these tools installed on your system:

| Dependency | Install | Required for |
|---|---|---|
| [FFmpeg](https://ffmpeg.org/) | `brew install ffmpeg` / `winget install ffmpeg` | Video/audio conversion |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | `brew install yt-dlp` / `winget install yt-dlp` | YouTube downloads |

```bash
# macOS
brew install ffmpeg yt-dlp

# Windows
winget install ffmpeg yt-dlp
```

On first launch, the app will check for FFmpeg and offer to install it via Homebrew.

## Building

```bash
# Debug build and run (macOS)
make run

# Release build (macOS)
make release VERSION=1.0.0
# → dist/media_converter-1.0.0-macos.zip
```

### Windows

```bash
flutter build windows --release
# → build\windows\x64\runner\Release\
```

### GitHub Actions

Push a tag to automatically build both platforms:

```bash
git tag v1.0.0
git push origin v1.0.0
```

On first launch, the app will check for FFmpeg and offer to install it via Homebrew.

## Makefile Commands

| Command | Description |
|---|---|
| `make setup` | Install dependencies |
| `make analyze` | Run the Dart analyzer |
| `make test` | Run all tests |
| `make run` | Build and launch on macOS |
| `make release VERSION=x.y.z` | Build release version and create ZIP archive |
| `make clean` | Clean build artifacts |
| `make purge` | Clean everything (derived data, caches) |
| `make format` | Format Dart source code |
| `make doctor` | Check Flutter installation status |

## Building

```bash
# Debug build and run
make run

# Release build
make release VERSION=1.0.0
# → dist/media_converter-1.0.0-macos.zip

# Windows (from Windows)
make build platform=windows
```

## Download

Pre-built binaries are available on the [Releases](https://github.com/evgenykon/media-converter/releases) page.

1. Download `media_converter-*-macos.zip`
2. Extract and move `media_converter.app` to Applications
3. Run `brew install ffmpeg yt-dlp`
4. Open the app

## Features

- Video conversion between formats (MP4, WebM, AVI, MOV, GIF, etc.)
- Audio extraction (MP3, AAC, FLAC, OGG)
- Hardware acceleration (VideoToolbox on macOS)
- YouTube video/audio download with format selection
- Conversion history
- System notifications
