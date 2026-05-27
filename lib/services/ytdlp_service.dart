import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class YtDlpService {
  static bool? _available;

  static Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    for (final path in [
      '/opt/homebrew/bin/yt-dlp',
      '/usr/local/bin/yt-dlp',
      '/usr/bin/yt-dlp',
    ]) {
      if (File(path).existsSync()) {
        _available = true;
        return true;
      }
    }
    try {
      final result = await Process.run('yt-dlp', ['--version'],
        environment: {'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'},
      );
      _available = result.exitCode == 0;
      return _available!;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  Future<void> download({
    required String url,
    required String outputPath,
    required String format,
    bool subtitles = false,
    bool thumbnail = false,
    bool isAudio = false,
    required void Function(double progress) onProgress,
    required void Function(bool success, String? error) onComplete,
  }) async {
    final args = <String>[
      '--newline',
      '--cookies-from-browser', 'chrome',
      '--extractor-args', 'youtube:player_client=tv',
      '-o', outputPath,
    ];

    if (isAudio) {
      if (format == 'mp3' || format.contains('[ext=mp3]')) {
        args.addAll(['-x', '--audio-format', 'mp3']);
      } else if (format.contains('[ext=flac]')) {
        args.addAll(['-x', '--audio-format', 'flac']);
      } else if (format.contains('[ext=webm]')) {
        args.addAll(['-x', '--audio-format', 'opus']);
      } else {
        args.add('-x');
      }
    } else {
      args.addAll(['-f', format, '--merge-output-format', 'mp4']);
    }

    if (subtitles) {
      args.addAll(['--write-subs', '--sub-langs', 'en,ru', '--embed-subs']);
    }
    if (thumbnail) {
      args.addAll(['--embed-thumbnail']);
    }

    args.add(url);

    debugPrint('yt-dlp args: ${args.join(" ")}');

    try {
      final ytDlp = await _findBinary();
      final process = await Process.start(ytDlp, args,
        environment: {
          'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin',
          'NPM_CONFIG_USERCONFIG': '/dev/null',
        },
      );

      final errors = StringBuffer();

      process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.contains('[download]') && line.contains('%')) {
            final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(line);
            if (percentMatch != null) {
              final p = double.tryParse(percentMatch.group(1)!);
              if (p != null) onProgress(p / 100);
            }
          }
        });

      process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          errors.writeln(line);
          if (line.contains('[download]') && line.contains('%')) {
            final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(line);
            if (percentMatch != null) {
              final p = double.tryParse(percentMatch.group(1)!);
              if (p != null) onProgress(p / 100);
            }
          }
        });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        onComplete(true, null);
      } else {
        final errMsg = errors.toString().trim();
        onComplete(false, errMsg.isNotEmpty ? errMsg : 'Код ошибки yt-dlp: $exitCode');
      }
    } catch (e, s) {
      debugPrint('yt-dlp error: $e\n$s');
      onComplete(false, 'Ошибка: $e');
    }
  }

  Future<String> _findBinary() async {
    for (final path in [
      '/opt/homebrew/bin/yt-dlp',
      '/usr/local/bin/yt-dlp',
      '/usr/bin/yt-dlp',
    ]) {
      if (File(path).existsSync()) return path;
    }
    return 'yt-dlp';
  }
}
