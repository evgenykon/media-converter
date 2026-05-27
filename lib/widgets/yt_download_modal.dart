import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ytdlp_service.dart';

class YtDownloadResult {
  final String url;
  final String outputName;
  final String outputPath;
  final String formatArg;
  final bool downloadSubtitles;
  final bool embedThumbnail;
  YtDownloadResult({
    required this.url,
    required this.outputName,
    required this.outputPath,
    required this.formatArg,
    this.downloadSubtitles = false,
    this.embedThumbnail = false,
  });
}

final _resolutions = [
  ('bestvideo', 'Лучшее'),
  ('bestvideo[height<=4320]', '4K'),
  ('bestvideo[height<=2160]', '1440p'),
  ('bestvideo[height<=1080]', '1080p'),
  ('bestvideo[height<=720]', '720p'),
  ('bestvideo[height<=480]', '480p'),
  ('bestvideo[height<=360]', '360p'),
];

final _audioFormats = [
  ('bestaudio', 'Лучшее'),
  ('aac', 'AAC'),
  ('mp3', 'MP3'),
  ('opus', 'Opus'),
  ('flac', 'FLAC'),
];

final _codecs = ['avc1', 'vp9', 'av01', ''];

String _codecLabel(String c) {
  switch (c) {
    case 'avc1': return 'H.264';
    case 'vp9': return 'VP9';
    case 'av01': return 'AV1';
    default: return 'Авто';
  }
}

Future<YtDownloadResult?> showYtDownloadModal(BuildContext context) {
  return showDialog<YtDownloadResult>(
    context: context,
    builder: (_) => const _YtDownloadModal(),
  );
}

class _YtDownloadModal extends StatefulWidget {
  const _YtDownloadModal();

  @override
  State<_YtDownloadModal> createState() => _YtDownloadModalState();
}

class _YtDownloadModalState extends State<_YtDownloadModal> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  String _resolution = 'bestvideo';
  String _audioFormat = 'bestaudio';
  String _codec = 'avc1';
  bool _subtitles = false;
  bool _thumbnail = false;
  bool _advancedOpen = false;
  String _outputDir = '';
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final home = Platform.environment['HOME'] ?? '';
    _outputDir = '$home/Downloads';
    _updateName();
  }

  void _updateName() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    _nameController.text = 'youtube_$ts';
  }

  bool get _isAudioOnly => _resolution == 'audio_only';

  String get _ext {
    if (_isAudioOnly) {
      if (_audioFormat == 'mp3') return 'mp3';
      if (_audioFormat == 'flac') return 'flac';
      if (_audioFormat == 'opus') return 'opus';
      return 'm4a';
    }
    return 'mp4';
  }

  String get _formatArg {
    if (_isAudioOnly) {
      if (_audioFormat == 'bestaudio') return 'bestaudio';
      if (_audioFormat == 'mp3') return 'bestaudio[ext=mp3]';
      if (_audioFormat == 'flac') return 'bestaudio[ext=flac]';
      if (_audioFormat == 'opus') return 'bestaudio[ext=webm]';
      return 'bestaudio[ext=m4a]';
    }
    final res = _resolution;
    final codecFilter = _codec.isNotEmpty ? '[vcodec*=$_codec]' : '';
    return '$res$codecFilter+bestaudio';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir != null && mounted) {
      setState(() => _outputDir = dir);
    }
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    final name = _nameController.text.trim();
    final outputName = name.isNotEmpty ? '$name.$_ext' : 'youtube_video.$_ext';
    final outputPath = '$_outputDir/$outputName';

    await YtDlpService().download(
      url: url,
      outputPath: outputPath,
      format: _formatArg,
      isAudio: _isAudioOnly,
      subtitles: _subtitles,
      thumbnail: _thumbnail,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onComplete: (success, error) {
        if (!mounted) return;
        if (success) {
          Navigator.of(context).pop(YtDownloadResult(
            url: url,
            outputName: outputName,
            outputPath: outputPath,
            formatArg: _formatArg,
            downloadSubtitles: _subtitles,
            embedThumbnail: _thumbnail,
          ));
        } else {
          setState(() {
            _downloading = false;
            _error = error;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.download, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Скачать с YouTube', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (!_downloading)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Будет запрошен доступ к связке ключей Chrome для получения cookies.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                enabled: !_downloading,
                decoration: const InputDecoration(
                  labelText: 'Ссылка на видео',
                  hintText: 'https://youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _resolution,
                decoration: const InputDecoration(
                  labelText: 'Качество видео',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  ..._resolutions.map((r) => DropdownMenuItem(
                    value: r.$1,
                    child: Text(r.$2, style: const TextStyle(fontSize: 13)),
                  )),
                  const DropdownMenuItem(
                    value: 'audio_only',
                    child: Text('Только аудио', style: TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: _downloading ? null : (v) {
                  if (v != null) setState(() => _resolution = v);
                },
              ),
              if (!_isAudioOnly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _codec,
                  decoration: const InputDecoration(
                    labelText: 'Кодек',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _codecs.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(_codecLabel(c), style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: _downloading ? null : (v) {
                    if (v != null) setState(() => _codec = v);
                  },
                ),
              ],
              if (_isAudioOnly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _audioFormat,
                  decoration: const InputDecoration(
                    labelText: 'Формат аудио',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _audioFormats.map((a) => DropdownMenuItem(
                    value: a.$1,
                    child: Text(a.$2, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: _downloading ? null : (v) {
                    if (v != null) setState(() => _audioFormat = v);
                  },
                ),
              ],
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _advancedOpen = !_advancedOpen),
                child: Row(
                  children: [
                    Icon(_advancedOpen ? Icons.expand_less : Icons.expand_more, size: 18,
                      color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('Дополнительно', style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              if (_advancedOpen) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Субтитры', style: TextStyle(fontSize: 13)),
                          subtitle: const Text('Скачать субтитры', style: TextStyle(fontSize: 11)),
                          value: _subtitles,
                          onChanged: _downloading ? null : (v) => setState(() => _subtitles = v),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Обложка', style: TextStyle(fontSize: 13)),
                          subtitle: const Text('Встроить обложку видео', style: TextStyle(fontSize: 11)),
                          value: _thumbnail,
                          onChanged: _downloading ? null : (v) => setState(() => _thumbnail = v),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      enabled: !_downloading,
                      decoration: InputDecoration(
                        labelText: 'Имя файла',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        suffixText: '.$_ext',
                        suffixStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.folder_open, color: theme.colorScheme.primary),
                    onPressed: _downloading ? null : _pickDirectory,
                    tooltip: 'Выбрать папку',
                    style: IconButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              if (!_downloading) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('$_outputDir/', style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error))),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _error!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ошибка скопирована'), duration: Duration(seconds: 2)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.copy, size: 16, color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
              if (_downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress.clamp(0.0, 1.0)),
                const SizedBox(height: 8),
                Text('${(_progress * 100).round()}%', style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _downloading ? null : _startDownload,
                  icon: Icon(_downloading ? Icons.hourglass_top : Icons.download, size: 20),
                  label: Text(_downloading ? 'Скачивание...' : 'Скачать'),
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
