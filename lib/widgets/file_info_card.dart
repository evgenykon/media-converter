import 'package:flutter/material.dart';

import '../models/media_file.dart';

class FileInfoCard extends StatelessWidget {
  final MediaFile file;
  final bool compact;

  const FileInfoCard({super.key, required this.file, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Row(
          children: [
            Icon(
              file.isVideo ? Icons.videocam : Icons.audiotrack,
              size: compact ? 28 : 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(file.name, style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${file.formatFormatted} • ${file.sizeFormatted}${file.isVideo ? ' • ${file.resolution}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
