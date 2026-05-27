import 'package:flutter/material.dart';

import '../models/media_file.dart';
import '../models/preset.dart';
import 'comparison_table.dart';
import 'file_info_card.dart';
import 'preset_tile.dart';

class PresetModalResult {
  final Preset preset;
  PresetModalResult(this.preset);
}

Future<PresetModalResult?> showPresetModal({
  required BuildContext context,
  required MediaFile file,
  required List<Preset> presets,
}) {
  return showModalBottomSheet<PresetModalResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PresetModalContent(file: file, presets: presets),
  );
}

class _PresetModalContent extends StatefulWidget {
  final MediaFile file;
  final List<Preset> presets;

  const _PresetModalContent({required this.file, required this.presets});

  @override
  State<_PresetModalContent> createState() => _PresetModalContentState();
}

class _PresetModalContentState extends State<_PresetModalContent> {
  Preset? _selected;
  PresetCategory _activeCategory = PresetCategory.video;

  List<Preset> get _filteredPresets =>
      widget.presets.where((p) => p.category == _activeCategory).toList();

  @override
  void initState() {
    super.initState();
    if (_filteredPresets.isNotEmpty) {
      _selected = _filteredPresets.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  FileInfoCard(file: widget.file),
                  const SizedBox(height: 16),
                  _categoryTabs(),
                  const SizedBox(height: 8),
                  ..._filteredPresets.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: PresetTile(
                      preset: p,
                      selected: _selected == p,
                      onTap: () => setState(() => _selected = p),
                    ),
                  )),
                  if (_selected != null) ...[
                    const SizedBox(height: 16),
                    ComparisonTable(source: widget.file, preset: _selected!),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(PresetModalResult(_selected!));
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Старт'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTabs() {
    final categories = PresetCategory.values;
    return SegmentedButton<PresetCategory>(
      segments: categories.map((cat) {
        String label;
        switch (cat) {
          case PresetCategory.video:
            label = 'Видео';
            break;
          case PresetCategory.audio:
            label = 'Аудио';
            break;
          case PresetCategory.device:
            label = 'Устройства';
            break;
        }
        return ButtonSegment(value: cat, label: Text(label));
      }).toList(),
      selected: {_activeCategory},
      onSelectionChanged: (selected) {
        setState(() {
          _activeCategory = selected.first;
          if (_filteredPresets.isNotEmpty && !_filteredPresets.contains(_selected)) {
            _selected = _filteredPresets.first;
          }
        });
      },
    );
  }
}
