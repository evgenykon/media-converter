import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyState({
    super.key,
    this.title = 'Нет конвертаций',
    this.subtitle = 'Нажмите «Конвертировать», чтобы начать',
    this.icon = Icons.video_library_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
