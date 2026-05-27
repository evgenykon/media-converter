import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/conversion_job.dart';
import '../models/media_file.dart';
import '../models/preset.dart';
import '../services/ffmpeg_service.dart';
import '../services/history_service.dart';
import '../services/media_info_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

final ffmpegServiceProvider = Provider<FfmpegService>((ref) => FfmpegService());
final mediaInfoServiceProvider = Provider<MediaInfoService>((ref) => MediaInfoService());
final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());

class ConversionState {
  final List<ConversionJob> jobs;
  final MediaFile? selectedFile;
  final bool isLoadingMediaInfo;

  ConversionState({
    this.jobs = const [],
    this.selectedFile,
    this.isLoadingMediaInfo = false,
  });

  ConversionState copyWith({
    List<ConversionJob>? jobs,
    MediaFile? selectedFile,
    bool? isLoadingMediaInfo,
  }) => ConversionState(
    jobs: jobs ?? this.jobs,
    selectedFile: selectedFile ?? this.selectedFile,
    isLoadingMediaInfo: isLoadingMediaInfo ?? this.isLoadingMediaInfo,
  );
}

class ConversionProvider extends Notifier<ConversionState> {
  final Uuid _uuid = const Uuid();

  @override
  ConversionState build() => ConversionState();

  Future<void> loadHistory() async {
    final jobs = await ref.read(historyServiceProvider).load();
    state = state.copyWith(jobs: jobs);
  }

  Future<MediaFile?> pickAndAnalyzeFile(String path) async {
    state = state.copyWith(isLoadingMediaInfo: true);
    try {
      final info = await ref.read(mediaInfoServiceProvider).getMediaInfo(path);
      debugPrint('Media info parsed: ${info.name} format=${info.format} videoCodec=${info.videoCodec} duration=${info.durationSeconds}');
      state = state.copyWith(selectedFile: info, isLoadingMediaInfo: false);
      return info;
    } catch (e, s) {
      debugPrint('pickAndAnalyzeFile error: $e\n$s');
      state = state.copyWith(isLoadingMediaInfo: false);
      return null;
    }
  }

  void clearSelectedFile() {
    state = state.copyWith(selectedFile: null);
  }

  Future<String> startConversion({
    required MediaFile source,
    required Preset preset,
    String speed = 'medium',
    bool useHardware = false,
    String? outputName,
  }) async {
    final id = _uuid.v4();
    final dir = _getDefaultOutputDir(source.path);
    final ext = preset.container;
    final defaultName = source.name.contains('.')
        ? source.name.substring(0, source.name.lastIndexOf('.'))
        : source.name;
    final outName = (outputName != null && outputName.isNotEmpty)
        ? outputName
        : '$defaultName.$ext';
    final outputPath = '${dir.path}/$outName';

    var job = ConversionJob(
      id: id,
      source: source,
      preset: preset,
      outputPath: outputPath,
      status: JobStatus.running,
    );

    state = state.copyWith(jobs: [job, ...state.jobs]);

    await ref.read(ffmpegServiceProvider).execute(
      jobId: id,
      source: source,
      preset: preset,
      outputPath: outputPath,
      speed: speed,
      useHardware: useHardware,
      onProgress: (progress, sizeBytes, speed) {
        final updated = job.copyWith(progress: progress.clamp(0.0, 1.0));
        _updateJob(updated);
        job = updated;
      },
      onComplete: (success, error) async {
        final now = DateTime.now();
        if (success) {
          int? outputSize;
          try {
            final outFile = File(outputPath);
            if (await outFile.exists()) {
              outputSize = await outFile.length();
            }
          } catch (_) {}
          job = job.copyWith(
            status: JobStatus.completed,
            completedAt: now,
            progress: 1.0,
            outputSizeBytes: outputSize,
          );
        } else if (error == 'Отменено пользователем') {
          job = job.copyWith(
            status: JobStatus.cancelled,
            completedAt: now,
          );
        } else {
          job = job.copyWith(
            status: JobStatus.failed,
            completedAt: now,
            errorMessage: error,
          );
        }
        _updateJob(job);

        if (success && ref.read(settingsProvider).notificationsEnabled) {
          await NotificationService.instance.showNotification(
            id: now.millisecondsSinceEpoch ~/ 1000,
            title: 'Конвертация завершена',
            body: source.name,
          );
        }

        await ref.read(historyServiceProvider).save(state.jobs);
      },
    );

    return id;
  }

  void cancelJob(String id) {
    final ffmpeg = ref.read(ffmpegServiceProvider);
    if (ffmpeg.activeJobId == id) {
      ffmpeg.cancel();
    }
    final idx = state.jobs.indexWhere((j) => j.id == id);
    if (idx == -1) return;
    final job = state.jobs[idx];
    if (job.status == JobStatus.pending || job.status == JobStatus.running) {
      final updated = job.copyWith(
        status: JobStatus.cancelled,
        completedAt: DateTime.now(),
      );
      _updateJob(updated);
    }
  }

  void removeJob(String id) {
    final jobs = state.jobs.where((j) => j.id != id).toList();
    state = state.copyWith(jobs: jobs);
    ref.read(historyServiceProvider).save(jobs);
  }

  Future<void> addYtDownload({
    required String outputPath,
    required String outputName,
    required String url,
    required String formatArg,
    bool downloadSubtitles = false,
    bool embedThumbnail = false,
  }) async {
    var file = File(outputPath);
    if (!await file.exists()) {
      for (final alt in ['.webm', '.mkv', '.m4a', '.mp3']) {
        final altFile = File(outputPath + alt);
        if (await altFile.exists()) {
          file = altFile;
          break;
        }
      }
    }
    final size = await file.length();
    final now = DateTime.now();
    final name = file.path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last : 'mp4';
    final source = MediaFile(
      path: outputPath,
      name: name,
      sizeBytes: size,
      format: ext,
    );

    final preset = Preset(
      name: 'YouTube: $formatArg',
      category: PresetCategory.video,
      container: ext,
      description: url,
    );

    final job = ConversionJob(
      id: _uuid.v4(),
      source: source,
      preset: preset,
      outputPath: outputPath,
      status: JobStatus.completed,
      progress: 1.0,
      createdAt: now,
      completedAt: now,
      outputSizeBytes: size,
    );

    state = state.copyWith(jobs: [job, ...state.jobs]);
    await ref.read(historyServiceProvider).save(state.jobs);
  }

  void clearHistory() {
    state = state.copyWith(jobs: []);
    ref.read(historyServiceProvider).save([]);
  }

  void _updateJob(ConversionJob updated) {
    final jobs = state.jobs.map((j) => j.id == updated.id ? updated : j).toList();
    state = state.copyWith(jobs: jobs);
  }

  Directory _getDefaultOutputDir(String sourcePath) {
    return Directory(sourcePath).parent;
  }
}

final conversionProvider = NotifierProvider<ConversionProvider, ConversionState>(
  ConversionProvider.new,
);
