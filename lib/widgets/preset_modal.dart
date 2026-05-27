import 'package:flutter/material.dart';

import '../models/media_file.dart';
import '../models/preset.dart';

class PresetModalResult {
  final Preset preset;
  PresetModalResult(this.preset);
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
    final firstPresets = _categoryPresets;
    if (firstPresets.isNotEmpty) {
      _selected = firstPresets.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(PresetModalResult(_selected!));
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
        onTap: () => setState(() => _selected = preset),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _chip(theme, '${source.formatFormatted} → ${preset.containerFormatted}', Icons.swap_horiz),
            const SizedBox(width: 8),
            _chip(theme, source.sizeFormatted, Icons.sd_storage),
            const SizedBox(width: 8),
            _chip(theme, estimatedStr, Icons.sd_storage_outlined),
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
