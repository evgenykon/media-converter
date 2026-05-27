import 'package:flutter/material.dart';


class ProgressSection extends StatelessWidget {
  final double progress;
  final String label;

  const ProgressSection({super.key, required this.progress, this.label = 'Конвертация...'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(value: progress, minHeight: 8),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text('$percent%', style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ],
    );
  }
}
