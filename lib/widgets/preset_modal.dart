import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_file.dart';
import '../models/preset.dart';
import '../services/ffmpeg_service.dart';

class PresetModalResult {
  final Preset preset;
  final String speed;
  final bool useHardware;
  final String outputName;
  PresetModalResult(this.preset, {this.speed = 'medium', this.useHardware = false, required this.outputName});
}

Future<PresetModalResult?> showPresetModal({
  required BuildContext context,
  required MediaFile file,
  required List<Preset> presets,
}) {
  return showDialog<PresetModalResult>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: _PresetModalContent(file: file, presets: presets),
    ),
  );
}

class _PresetModalContent extends StatefulWidget {
  final MediaFile file;
  final List<Preset> presets;

  const _PresetModalContent({required this.file, required this.presets});

  @override
  State<_PresetModalContent> createState() => _PresetModalContentState();
}

class _PresetModalContentState extends State<_PresetModalContent>
    with SingleTickerProviderStateMixin {
  Preset? _selected;
  late TabController _tabController;
  String _speed = FfmpegService.defaultSpeed;
  bool _useHardware = FfmpegService.useHardwareAccelerationDefault;
  final _outputNameController = TextEditingController();

  String _outputNameFor(Preset p) {
    final name = widget.file.name;
    final base = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    final ext = p.container;
    final dir = _outputDir;
    var candidate = '$base.$ext';
    var counter = 1;
    while (File('${dir.path}/$candidate').existsSync()) {
      candidate = '$base ($counter).$ext';
      counter++;
    }
    return candidate;
  }

  Directory get _outputDir => Directory(widget.file.path).parent;

  static const _tabs = ['Инфо', 'Видео', 'Аудио', 'Устройства'];

  bool get _isInfoTab => _tabController.index == 0;

  PresetCategory? get _activeCategory {
    final idx = _tabController.index - 1;
    if (idx < 0 || idx >= PresetCategory.values.length) return null;
    return PresetCategory.values[idx];
  }

  List<Preset> get _categoryPresets {
    final cat = _activeCategory;
    if (cat == null) return [];
    return widget.presets.where((p) => p.category == cat).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (!_isInfoTab) {
            final presets = _categoryPresets;
            if (presets.isNotEmpty && !presets.contains(_selected)) {
              _selected = presets.first;
            }
          }
        });
      }
    });
    final initialPresets = widget.presets.where((p) => p.category == PresetCategory.video).toList();
    if (initialPresets.isNotEmpty) {
      _selected = initialPresets.first;
      _outputNameController.text = _outputNameFor(_selected!);
    }
  }

  void _onPresetChanged(Preset preset) {
    setState(() {
      _selected = preset;
      _outputNameController.text = _outputNameFor(preset);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _outputNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(widget.file.isVideo ? Icons.videocam : Icons.audiotrack,
                  size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.file.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelStyle: theme.textTheme.labelMedium,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
        ),
        Flexible(
          child: TabBarView(
            controller: _tabController,
            children: [
              _infoTab(theme),
              _presetsTab(PresetCategory.video, theme),
              _presetsTab(PresetCategory.audio, theme),
              _presetsTab(PresetCategory.device, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTab(ThemeData theme) {
    final f = widget.file;
    final rows = <_InfoRow>[
      _InfoRow('Имя файла', f.name),
      _InfoRow('Формат', f.formatFormatted),
      _InfoRow('Размер', f.sizeFormatted),
      _InfoRow('Длительность', f.durationFormatted),
    ];

    if (f.isVideo) {
      rows.addAll([
        _InfoRow('Разрешение', f.resolution),
        _InfoRow('Видео кодек', f.videoCodec ?? '—'),
        _InfoRow('Битрейт видео', f.videoBitrateFormatted),
      ]);
    }

    rows.addAll([
      _InfoRow('Аудио кодек', f.audioCodec ?? '—'),
      _InfoRow('Битрейт аудио', f.audioBitrateFormatted),
    ]);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Card(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _infoRowWidget(rows[i], theme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRowWidget(_InfoRow row, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(row.label, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(row.value, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500),
              textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _presetsTab(PresetCategory category, ThemeData theme) {
    final presets = widget.presets.where((p) => p.category == category).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      shrinkWrap: true,
      children: [
        ...presets.map((p) => _compactTile(p, theme)),
        if (_selected != null) ...[
          const SizedBox(height: 8),
          _summaryBar(theme),
          if (_selected!.category != PresetCategory.audio) ...[
            const SizedBox(height: 8),
            _speedSelector(theme),
          ],
          const SizedBox(height: 8),
          _outputNameField(theme),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: () {
                final name = _outputNameController.text.trim();
                Navigator.of(context).pop(PresetModalResult(_selected!,
                  speed: _speed,
                  useHardware: _useHardware,
                  outputName: name.isNotEmpty ? name : _outputNameFor(_selected!),
                ));
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Старт'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _compactTile(Preset preset, ThemeData theme) {
    final isSelected = _selected == preset;
    Widget trailing;
    if (preset.category == PresetCategory.audio) {
      trailing = Text(preset.audioCodecFormatted, style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant));
    } else if (preset.category == PresetCategory.device) {
      trailing = Text(preset.resolutionFormatted, style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant));
    } else {
      trailing = Text(preset.videoCodecFormatted, style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
                        onTap: () => _onPresetChanged(preset),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(preset.name, style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedSelector(ThemeData theme) {
    final isH264 = _selected!.videoCodec == 'libx264' || _selected!.videoCodec == 'libx265';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Скорость', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (isH264)
                  SizedBox(
                    height: 28,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _useHardware,
                        onChanged: (v) => setState(() => _useHardware = v),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                if (isH264)
                  GestureDetector(
                    onTap: () => setState(() => _useHardware = !_useHardware),
                    child: Text('Аппаратное', style: theme.textTheme.labelSmall?.copyWith(
                      color: _useHardware ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    )),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FfmpegService.speedPresets.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    selected: _speed == s,
                    onSelected: !_useHardware ? (v) => setState(() => _speed = s) : null,
                    visualDensity: VisualDensity.compact,
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outputNameField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _outputNameController,
        decoration: InputDecoration(
          labelText: 'Имя выходного файла',
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: Icon(Icons.edit, size: 16, color: theme.colorScheme.outline),
        ),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _summaryBar(ThemeData theme) {
    final source = widget.file;
    final preset = _selected!;

    final estimated = preset.estimateSizeBytes(
      inputVideoBitrate: source.videoBitrate,
      inputAudioBitrate: source.audioBitrate,
      durationSeconds: source.durationSeconds,
    );
    final estimatedStr = estimated > 0
        ? '~${estimated < 1024 * 1024 ? "${(estimated / 1024).toStringAsFixed(0)} KB" : estimated < 1024 * 1024 * 1024 ? "${(estimated / (1024 * 1024)).toStringAsFixed(1)} MB" : "${(estimated / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB"}'
        : '—';

    final outputName = _outputNameController.text.trim();
    final displayName = outputName.isNotEmpty ? outputName : _outputNameFor(preset);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(child: Text(displayName, style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(theme, '${source.name} • ${source.sizeFormatted}', Icons.sd_storage),
                const SizedBox(width: 8),
                _chip(theme, estimatedStr, Icons.sd_storage_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, String text, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(child: Text(text, style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}
