import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/media_file.dart';
import '../models/preset.dart';
import 'ffmpeg_checker.dart';

class FfmpegService {
  Process? _activeProcess;
  String? _activeJobId;

  static const speedPresets = [
    'ultrafast', 'superfast', 'veryfast', 'faster', 'fast',
    'medium', 'slow', 'slower', 'veryslow',
  ];

  static const defaultSpeed = 'medium';
  static const useHardwareAccelerationDefault = false;

  List<String> _buildArgs({
    required String inputPath,
    required String outputPath,
    required Preset preset,
    required MediaFile source,
    String speed = defaultSpeed,
    bool useHardware = useHardwareAccelerationDefault,
  }) {
    final args = <String>['-y', '-i', inputPath];

    if (preset.videoCodec != null && source.isVideo) {
      if (useHardware) {
        if (preset.videoCodec == 'libx264') {
          args.addAll(['-c:v', 'h264_videotoolbox']);
        } else if (preset.videoCodec == 'libx265') {
          args.addAll(['-c:v', 'hevc_videotoolbox']);
        } else {
          args.addAll(['-c:v', preset.videoCodec!]);
        }
      } else {
        args.addAll(['-c:v', preset.videoCodec!]);
      }
    }

    if (preset.audioCodec != null) {
      args.addAll(['-c:a', preset.audioCodec!]);
    } else if (preset.videoCodec != null && source.isVideo) {
      args.add('-an');
    }

    if (preset.videoBitrate != null && source.isVideo) {
      args.addAll(['-b:v', preset.videoBitrate.toString()]);
    }

    if (preset.audioBitrate != null) {
      args.addAll(['-b:a', preset.audioBitrate.toString()]);
    }

    if (!preset.preserveResolution && preset.width != null && preset.height != null) {
      args.addAll(['-vf', 'scale=${preset.width}:${preset.height}']);
    }

    args.addAll(preset.extraArgs);

    if (!useHardware && source.isVideo && preset.videoCodec != null && preset.category == PresetCategory.video) {
      args.addAll(['-preset', speed]);
    }

    if (source.isVideo) {
      args.addAll(['-threads', 'auto']);
    }

    args.addAll(['-progress', 'pipe:1']);
    args.add(outputPath);

    return args;
  }

  Future<void> execute({
    required String jobId,
    required MediaFile source,
    required Preset preset,
    required String outputPath,
    String speed = defaultSpeed,
    bool useHardware = useHardwareAccelerationDefault,
    required void Function(double progress, int? sizeBytes, double? speed) onProgress,
    required void Function(bool success, String? error) onComplete,
  }) async {
    final args = _buildArgs(
      inputPath: source.path,
      outputPath: outputPath,
      preset: preset,
      source: source,
      speed: speed,
      useHardware: useHardware,
    );

    debugPrint('FFmpeg args: $args');

    try {
      final ffmpeg = FfmpegChecker.ffmpegPath ?? 'ffmpeg';
      final process = await Process.start(ffmpeg, args,
        environment: {'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'},
      );
      _activeProcess = process;
      _activeJobId = jobId;

      double? durationSeconds = source.durationSeconds;

      process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.startsWith('out_time_us=')) {
            final us = int.tryParse(line.split('=')[1]);
            if (us != null && durationSeconds != null && durationSeconds > 0) {
              final progress = (us / 1000000 / durationSeconds).clamp(0.0, 1.0);
              onProgress(progress, null, null);
            }
          }
        });

      process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          debugPrint('ffmpeg: $line');
        });

      final exitCode = await process.exitCode;
      _activeProcess = null;
      _activeJobId = null;

      if (exitCode == 0) {
        final outFile = File(outputPath);
        if (await outFile.exists()) {
          onComplete(true, null);
        } else {
          onComplete(false, 'Выходной файл не найден');
        }
      } else if (exitCode == -2 || exitCode == 255) {
        onComplete(false, 'Отменено пользователем');
      } else {
        onComplete(false, 'Код ошибки ffmpeg: $exitCode');
      }
    } catch (e, s) {
      debugPrint('FFmpeg execute error: $e\n$s');
      onComplete(false, 'Ошибка: $e');
      _activeProcess = null;
      _activeJobId = null;
    }
  }

  void cancel() {
    if (_activeProcess != null) {
      _activeProcess!.kill();
      _activeProcess = null;
      _activeJobId = null;
    }
  }

  bool get isActive => _activeProcess != null;
  String? get activeJobId => _activeJobId;
}
