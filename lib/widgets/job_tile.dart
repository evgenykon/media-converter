import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/conversion_job.dart';
import 'progress_section.dart';

class JobTile extends StatelessWidget {
  final ConversionJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenFolder;

  const JobTile({super.key, required this.job, this.onCancel, this.onDelete, this.onOpenFolder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _color(theme), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.source.name, style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${job.preset.name} • ${job.statusLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (job.status == JobStatus.running && onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'Отменить',
                  ),
              ],
            ),
            if (job.status == JobStatus.running) ...[
              const SizedBox(height: 12),
              ProgressSection(progress: job.progress),
            ],
            if (job.status == JobStatus.completed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip(theme, Icons.sd_storage, job.outputSizeFormatted),
                  const SizedBox(width: 8),
                  _infoChip(theme, Icons.schedule, job.durationFormatted),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.outline),
                      onPressed: onDelete,
                      tooltip: 'Удалить из истории',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onOpenFolder != null)
                    IconButton(
                      icon: Icon(Icons.folder_open, size: 18, color: theme.colorScheme.primary),
                      onPressed: onOpenFolder,
                      tooltip: 'Открыть папку с файлом',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            if (job.status == JobStatus.failed && job.errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(job.errorMessage!, style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    )),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: job.errorMessage!));
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
          ],
        ),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (job.status) {
      case JobStatus.pending:
        return Icons.hourglass_empty;
      case JobStatus.running:
        return Icons.sync;
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.failed:
        return Icons.error;
      case JobStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _color(ThemeData theme) {
    switch (job.status) {
      case JobStatus.pending:
        return theme.colorScheme.outline;
      case JobStatus.running:
        return theme.colorScheme.primary;
      case JobStatus.completed:
        return theme.colorScheme.primary;
      case JobStatus.failed:
        return theme.colorScheme.error;
      case JobStatus.cancelled:
        return theme.colorScheme.outline;
    }
  }
}
