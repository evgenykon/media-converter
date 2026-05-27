import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversion_job.dart';
import '../models/preset.dart';
import '../providers/conversion_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/job_tile.dart';
import '../widgets/preset_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionProvider);
    final jobs = state.jobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
            tooltip: 'Настройки',
          ),
          if (jobs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClearHistory(context, ref),
              tooltip: 'Очистить историю',
            ),
        ],
      ),
      body: jobs.isEmpty
          ? const EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: jobs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: JobTile(
                  job: jobs[index],
                  onCancel: jobs[index].status == JobStatus.running
                      ? () => ref.read(conversionProvider.notifier).cancelJob(jobs[index].id)
                      : null,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickFile(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Конвертировать'),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', '3gp',
        'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma',
      ],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    final file = await ref.read(conversionProvider.notifier).pickAndAnalyzeFile(path);
    if (file == null || !context.mounted) return;

    final presets = await _loadPresets();
    final modalResult = await showPresetModal(
      context: context,
      file: file,
      presets: presets,
    );

    if (modalResult != null && context.mounted) {
      ref.read(conversionProvider.notifier).startConversion(
        source: file,
        preset: modalResult.preset,
      );
    }

    if (context.mounted) {
      ref.read(conversionProvider.notifier).clearSelectedFile();
    }
  }

  Future<List<Preset>> _loadPresets() async {
    try {
      final data = await rootBundle.loadString('data/presets.json');
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Preset.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultPresets;
    }
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(settings: settings),
    );
  }

  void _confirmClearHistory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text('Все записи о конвертациях будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(onPressed: () {
            ref.read(conversionProvider.notifier).clearHistory();
            Navigator.pop(ctx);
          }, child: const Text('Очистить')),
        ],
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final SettingsProvider settings;
  const _SettingsDialog({required this.settings});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.settings.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Настройки'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Уведомления'),
            subtitle: const Text('Показывать системное уведомление о завершении'),
            value: _notifications,
            onChanged: (v) {
              setState(() => _notifications = v);
              widget.settings.setNotificationsEnabled(v);
            },
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Готово')),
      ],
    );
  }
}

final List<Preset> _defaultPresets = [
  Preset(name: 'MP4 H.264', category: PresetCategory.video, container: 'mp4', videoCodec: 'libx264', audioCodec: 'aac', description: 'Универсальный формат, баланс качества и размера', extraArgs: ['-preset', 'medium', '-pix_fmt', 'yuv420p']),
  Preset(name: 'MP4 H.265 / HEVC', category: PresetCategory.video, container: 'mp4', videoCodec: 'libx265', audioCodec: 'aac', description: 'Лучшее сжатие, современный кодек', extraArgs: ['-preset', 'medium', '-pix_fmt', 'yuv420p']),
  Preset(name: 'WebM VP9', category: PresetCategory.video, container: 'webm', videoCodec: 'libvpx-vp9', audioCodec: 'libopus', description: 'Открытый формат для веба', extraArgs: ['-cpu-used', '2', '-deadline', 'good']),
  Preset(name: 'AVI', category: PresetCategory.video, container: 'avi', videoCodec: 'mpeg4', audioCodec: 'mp3', videoBitrate: 2000000, audioBitrate: 192000, description: 'Максимальная совместимость'),
  Preset(name: 'MOV', category: PresetCategory.video, container: 'mov', videoCodec: 'libx264', audioCodec: 'aac', description: 'Нативный формат Apple', extraArgs: ['-preset', 'medium']),
  Preset(name: 'GIF', category: PresetCategory.video, container: 'gif', videoCodec: null, audioCodec: null, preserveResolution: false, description: 'Анимированный GIF', extraArgs: ['-vf', 'fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse']),
  Preset(name: 'MP3 320kbps', category: PresetCategory.audio, container: 'mp3', videoCodec: null, audioCodec: 'libmp3lame', audioBitrate: 320000, description: 'Высокое качество аудио'),
  Preset(name: 'AAC 256kbps', category: PresetCategory.audio, container: 'm4a', videoCodec: null, audioCodec: 'aac', audioBitrate: 256000, description: 'Современный аудиоформат'),
  Preset(name: 'FLAC', category: PresetCategory.audio, container: 'flac', videoCodec: null, audioCodec: 'flac', description: 'Lossless аудио без потерь'),
  Preset(name: 'OGG Vorbis', category: PresetCategory.audio, container: 'ogg', videoCodec: null, audioCodec: 'libvorbis', audioBitrate: 192000, description: 'Открытый аудиоформат'),
  Preset(name: 'Для iPhone / iPad', category: PresetCategory.device, container: 'mp4', videoCodec: 'libx264', audioCodec: 'aac', videoBitrate: 5000000, audioBitrate: 128000, width: 1920, height: 1080, description: 'Оптимизировано для Apple', extraArgs: ['-preset', 'fast', '-pix_fmt', 'yuv420p', '-movflags', '+faststart']),
  Preset(name: 'Для Telegram', category: PresetCategory.device, container: 'mp4', videoCodec: 'libx264', audioCodec: 'aac', videoBitrate: 1000000, audioBitrate: 96000, width: 854, height: 480, description: 'Сжатие для мессенджеров', extraArgs: ['-preset', 'fast', '-pix_fmt', 'yuv420p']),
  Preset(name: 'Для YouTube', category: PresetCategory.device, container: 'mp4', videoCodec: 'libx264', audioCodec: 'aac', videoBitrate: 16000000, audioBitrate: 384000, width: 1920, height: 1080, description: 'Рекомендовано для YouTube', extraArgs: ['-preset', 'slow', '-pix_fmt', 'yuv420p', '-movflags', '+faststart']),
];
