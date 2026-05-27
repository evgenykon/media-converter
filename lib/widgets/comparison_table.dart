import 'package:flutter/material.dart';

import '../models/media_file.dart';
import '../models/preset.dart';

class ComparisonTable extends StatelessWidget {
  final MediaFile source;
  final Preset preset;

  const ComparisonTable({super.key, required this.source, required this.preset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!;
    final mutedStyle = style.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final headerStyle = theme.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сравнение', style: headerStyle),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  children: [
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('Параметр', style: mutedStyle),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Исходный', style: mutedStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Результат', style: mutedStyle),
                    ),
                  ],
                ),
                _row('Формат', source.formatFormatted, preset.containerFormatted),
                if (source.isVideo || preset.videoCodec != null)
                  _row('Видео кодек', source.videoCodec ?? '—', preset.videoCodecFormatted),
                if (source.audioCodec != null || preset.audioCodec != null)
                  _row('Аудио кодек', source.audioCodec ?? '—', preset.audioCodecFormatted),
                if (source.isVideo)
                  _row('Разрешение', source.resolution, preset.resolutionFormatted),
                if (source.isVideo)
                  _row('Битрейт видео', source.videoBitrateFormatted, preset.videoBitrateFormatted),
                _row('Битрейт аудио', source.audioBitrateFormatted, preset.audioBitrateFormatted),
                _row('Размер (оценка)', source.sizeFormatted, _estimatedSize),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _row(String label, String sourceVal, String presetVal) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(sourceVal),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(presetVal, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  String get _estimatedSize {
    final estimated = preset.estimateSizeBytes(
      inputVideoBitrate: source.videoBitrate,
      inputAudioBitrate: source.audioBitrate,
      durationSeconds: source.durationSeconds,
    );
    if (estimated <= 0) return '—';
    if (estimated < 1024 * 1024) return '~${(estimated / 1024).toStringAsFixed(0)} KB';
    if (estimated < 1024 * 1024 * 1024) {
      return '~${(estimated / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '~${(estimated / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
