import 'package:flutter/material.dart';

import '../models/preset.dart';

class PresetTile extends StatelessWidget {
  final Preset preset;
  final bool selected;
  final VoidCallback onTap;

  const PresetTile({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAudio = preset.category == PresetCategory.audio;

    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isAudio ? Icons.music_note : Icons.movie,
          color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.primary,
        ),
        title: Text(preset.name, style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        )),
        subtitle: preset.description != null ? Text(
          preset.description!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ) : null,
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
      ),
    );
  }
}
