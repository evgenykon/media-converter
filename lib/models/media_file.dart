import 'dart:io';

class MediaFile {
  final String path;
  final String name;
  final int sizeBytes;
  final String format;
  final String? videoCodec;
  final String? audioCodec;
  final int? width;
  final int? height;
  final double? durationSeconds;
  final int? videoBitrate;
  final int? audioBitrate;

  MediaFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.format,
    this.videoCodec,
    this.audioCodec,
    this.width,
    this.height,
    this.durationSeconds,
    this.videoBitrate,
    this.audioBitrate,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get resolution {
    if (width != null && height != null) return '${width}x$height';
    return '—';
  }

  String get durationFormatted {
    if (durationSeconds == null) return '—';
    final d = durationSeconds!;
    final hours = d ~/ 3600;
    final minutes = (d % 3600) ~/ 60;
    final secs = (d % 60).round();
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get videoBitrateFormatted {
    if (videoBitrate == null) return '—';
    final bps = videoBitrate!;
    if (bps < 1000) return '$bps bps';
    if (bps < 1000000) return '${(bps / 1000).toStringAsFixed(0)} kbps';
    return '${(bps / 1000000).toStringAsFixed(1)} Mbps';
  }

  String get audioBitrateFormatted {
    if (audioBitrate == null) return '—';
    final bps = audioBitrate!;
    if (bps < 1000) return '$bps bps';
    if (bps < 1000000) return '${(bps / 1000).toStringAsFixed(0)} kbps';
    return '${(bps / 1000000).toStringAsFixed(1)} Mbps';
  }

  String get formatFormatted {
    if (format.isEmpty) return '—';
    return format.toUpperCase();
  }

  bool get isVideo => videoCodec != null;

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'sizeBytes': sizeBytes,
    'format': format,
    'videoCodec': videoCodec,
    'audioCodec': audioCodec,
    'width': width,
    'height': height,
    'durationSeconds': durationSeconds,
    'videoBitrate': videoBitrate,
    'audioBitrate': audioBitrate,
  };

  factory MediaFile.fromJson(Map<String, dynamic> json) => MediaFile(
    path: json['path'] as String,
    name: json['name'] as String,
    sizeBytes: json['sizeBytes'] as int,
    format: json['format'] as String,
    videoCodec: json['videoCodec'] as String?,
    audioCodec: json['audioCodec'] as String?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
    videoBitrate: json['videoBitrate'] as int?,
    audioBitrate: json['audioBitrate'] as int?,
  );

  static Future<MediaFile> fromPath(String path) async {
    final file = File(path);
    final stat = await file.stat();
    final name = path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return MediaFile(
      path: path,
      name: name,
      sizeBytes: stat.size,
      format: ext,
    );
  }
}
