enum PresetCategory { video, audio, device }

class Preset {
  final String name;
  final PresetCategory category;
  final String container;
  final String? videoCodec;
  final String? audioCodec;
  final int? videoBitrate;
  final int? audioBitrate;
  final int? width;
  final int? height;
  final bool preserveResolution;
  final List<String> extraArgs;
  final String? description;

  Preset({
    required this.name,
    required this.category,
    required this.container,
    this.videoCodec,
    this.audioCodec,
    this.videoBitrate,
    this.audioBitrate,
    this.width,
    this.height,
    this.preserveResolution = true,
    this.extraArgs = const [],
    this.description,
  });

  String get categoryLabel {
    switch (category) {
      case PresetCategory.video:
        return 'Видео';
      case PresetCategory.audio:
        return 'Аудио';
      case PresetCategory.device:
        return 'Устройства';
    }
  }

  String get videoCodecFormatted {
    if (videoCodec == null) return '—';
    return videoCodec!;
  }

  String get audioCodecFormatted {
    if (audioCodec == null) return '—';
    return audioCodec!;
  }

  String get containerFormatted => container.toUpperCase();

  String get videoBitrateFormatted {
    if (videoBitrate == null) return 'Исходный';
    final bps = videoBitrate!;
    if (bps < 1000000) return '${(bps / 1000).toStringAsFixed(0)} kbps';
    return '${(bps / 1000000).toStringAsFixed(1)} Mbps';
  }

  String get audioBitrateFormatted {
    if (audioBitrate == null) return 'Исходный';
    final bps = audioBitrate!;
    if (bps < 1000) return '$bps bps';
    if (bps < 1000000) return '${(bps / 1000).toStringAsFixed(0)} kbps';
    return '${(bps / 1000000).toStringAsFixed(1)} Mbps';
  }

  String get resolutionFormatted {
    if (width != null && height != null) return '${width}x$height';
    if (preserveResolution) return 'Исходное';
    return 'Авто';
  }

  int estimateSizeBytes({
    required int? inputVideoBitrate,
    required int? inputAudioBitrate,
    required double? durationSeconds,
  }) {
    if (durationSeconds == null || durationSeconds <= 0) return 0;
    final vBitrate = videoBitrate ?? inputVideoBitrate ?? 2000000;
    final aBitrate = audioBitrate ?? inputAudioBitrate ?? 128000;
    final totalBitrate = vBitrate + aBitrate;
    return (totalBitrate * durationSeconds / 8).round();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category.name,
    'container': container,
    'videoCodec': videoCodec,
    'audioCodec': audioCodec,
    'videoBitrate': videoBitrate,
    'audioBitrate': audioBitrate,
    'width': width,
    'height': height,
    'preserveResolution': preserveResolution,
    'extraArgs': extraArgs,
    'description': description,
  };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
    name: json['name'] as String,
    category: PresetCategory.values.byName(json['category'] as String),
    container: json['container'] as String,
    videoCodec: json['videoCodec'] as String?,
    audioCodec: json['audioCodec'] as String?,
    videoBitrate: json['videoBitrate'] as int?,
    audioBitrate: json['audioBitrate'] as int?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    preserveResolution: json['preserveResolution'] as bool? ?? true,
    extraArgs: (json['extraArgs'] as List<dynamic>?)?.cast<String>() ?? [],
    description: json['description'] as String?,
  );
}
