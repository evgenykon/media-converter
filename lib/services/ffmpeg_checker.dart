import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class FfmpegChecker {
  static const _paths = [
    '/opt/homebrew/bin/ffmpeg',
    '/usr/local/bin/ffmpeg',
    '/usr/bin/ffmpeg',
    '/opt/homebrew/bin/ffprobe',
    '/usr/local/bin/ffprobe',
  ];

  static Future<bool> isAvailable() async {
    for (final path in _paths) {
      if (File(path).existsSync()) return true;
    }
    try {
      final result = await Process.run('ffmpeg', ['-version'],
        environment: {'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'},
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static String? get ffmpegPath {
    const bins = [
      '/opt/homebrew/bin/ffmpeg',
      '/usr/local/bin/ffmpeg',
      '/usr/bin/ffmpeg',
    ];
    for (final p in bins) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  static String? get ffprobePath {
    const bins = [
      '/opt/homebrew/bin/ffprobe',
      '/usr/local/bin/ffprobe',
      '/usr/bin/ffprobe',
    ];
    for (final p in bins) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  static Future<bool> installViaBrew() async {
    try {
      final process = await Process.start(
        '/bin/bash',
        ['-c', 'brew install ffmpeg'],
        environment: {'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'},
      );
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((d) => debugPrint(d));
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((d) => debugPrint(d));
      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
