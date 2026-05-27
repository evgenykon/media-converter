import 'dart:io';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';

import '../models/media_file.dart';
import '../models/preset.dart';

class FfmpegService {
  FFmpegSession? _activeSession;
  String? _activeJobId;

  String _buildCommand({
    required String inputPath,
    required String outputPath,
    required Preset preset,
    required MediaFile source,
  }) {
    final args = <String>['-y', '-i', inputPath];

    if (preset.videoCodec != null && source.isVideo) {
      args.addAll(['-c:v', preset.videoCodec!]);
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
    args.add(outputPath);

    return args.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
  }

  Future<void> execute({
    required String jobId,
    required MediaFile source,
    required Preset preset,
    required String outputPath,
    required void Function(double progress, int? sizeBytes, double? speed) onProgress,
    required void Function(bool success, String? error) onComplete,
  }) async {
    final command = _buildCommand(
      inputPath: source.path,
      outputPath: outputPath,
      preset: preset,
      source: source,
    );

    final session = await FFmpegKit.executeAsync(
      command,
      onStatistics: (Statistics statistics) {
        final progress = statistics.transcodingProgress ?? 0.0;
        onProgress(progress, statistics.size, statistics.speed);
      },
    );

    _activeSession = session;
    _activeJobId = jobId;

    final returnCode = session.getReturnCode();
    _activeSession = null;
    _activeJobId = null;

    if (ReturnCode.isSuccess(returnCode)) {
      final outFile = File(outputPath);
      if (await outFile.exists()) {
        onComplete(true, null);
      } else {
        onComplete(false, 'Выходной файл не найден');
      }
    } else if (ReturnCode.isCancel(returnCode)) {
      onComplete(false, 'Отменено пользователем');
    } else {
      final logs = session.getLogs();
      onComplete(false, logs ?? 'Неизвестная ошибка FFmpeg');
    }
  }

  void cancel() {
    if (_activeSession != null) {
      _activeSession!.cancel();
      _activeSession = null;
      _activeJobId = null;
    }
  }

  bool get isActive => _activeSession != null;
  String? get activeJobId => _activeJobId;
}
