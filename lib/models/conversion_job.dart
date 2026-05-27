import 'dart:convert';
import 'media_file.dart';
import 'preset.dart';

enum JobStatus { pending, running, completed, failed, cancelled }

class ConversionJob {
  final String id;
  final MediaFile source;
  final Preset preset;
  final String outputPath;
  final JobStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int? outputSizeBytes;

  ConversionJob({
    required this.id,
    required this.source,
    required this.preset,
    required this.outputPath,
    this.status = JobStatus.pending,
    this.progress = 0.0,
    DateTime? createdAt,
    this.completedAt,
    this.errorMessage,
    this.outputSizeBytes,
  }) : createdAt = createdAt ?? DateTime.now();

  ConversionJob copyWith({
    String? id,
    MediaFile? source,
    Preset? preset,
    String? outputPath,
    JobStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    int? outputSizeBytes,
  }) => ConversionJob(
    id: id ?? this.id,
    source: source ?? this.source,
    preset: preset ?? this.preset,
    outputPath: outputPath ?? this.outputPath,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
    errorMessage: errorMessage ?? this.errorMessage,
    outputSizeBytes: outputSizeBytes ?? this.outputSizeBytes,
  );

  String get outputSizeFormatted {
    if (outputSizeBytes == null) return '—';
    final bytes = outputSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get estimatedOutputSizeFormatted {
    final estimated = preset.estimateSizeBytes(
      inputVideoBitrate: source.videoBitrate,
      inputAudioBitrate: source.audioBitrate,
      durationSeconds: source.durationSeconds,
    );
    if (estimated <= 0) return '—';
    if (estimated < 1024 * 1024) {
      return '~${(estimated / (1024)).toStringAsFixed(0)} KB';
    }
    if (estimated < 1024 * 1024 * 1024) {
      return '~${(estimated / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '~${(estimated / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get durationFormatted {
    final seconds = source.durationSeconds;
    if (seconds == null) return '—';
    final d = seconds;
    final hours = d ~/ 3600;
    final minutes = (d % 3600) ~/ 60;
    final secs = (d % 60).round();
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get statusLabel {
    switch (status) {
      case JobStatus.pending:
        return 'Ожидает';
      case JobStatus.running:
        return 'Конвертируется';
      case JobStatus.completed:
        return 'Завершено';
      case JobStatus.failed:
        return 'Ошибка';
      case JobStatus.cancelled:
        return 'Отменено';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.toJson(),
    'preset': preset.toJson(),
    'outputPath': outputPath,
    'status': status.name,
    'progress': progress,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'outputSizeBytes': outputSizeBytes,
  };

  factory ConversionJob.fromJson(Map<String, dynamic> json) => ConversionJob(
    id: json['id'] as String,
    source: MediaFile.fromJson(json['source'] as Map<String, dynamic>),
    preset: Preset.fromJson(json['preset'] as Map<String, dynamic>),
    outputPath: json['outputPath'] as String,
    status: JobStatus.values.byName(json['status'] as String),
    progress: (json['progress'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    errorMessage: json['errorMessage'] as String?,
    outputSizeBytes: json['outputSizeBytes'] as int?,
  );

  String toJsonString() => jsonEncode(toJson());

  factory ConversionJob.fromJsonString(String source) =>
      ConversionJob.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
