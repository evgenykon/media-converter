import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/ffmpeg_checker.dart';

class MediaConverterApp extends ConsumerWidget {
  const MediaConverterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _FfmpegGuard(child: HomeScreen()),
    );
  }
}

class _FfmpegGuard extends StatefulWidget {
  final Widget child;
  const _FfmpegGuard({required this.child});

  @override
  State<_FfmpegGuard> createState() => _FfmpegGuardState();
}

class _FfmpegGuardState extends State<_FfmpegGuard> {
  bool _available = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    _available = await FfmpegChecker.isAvailable();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!_available) _showDialog();
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FfmpegDialog(
        onRetry: _check,
        onInstalled: () {
          Navigator.of(ctx).pop();
          _check();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}

class _FfmpegDialog extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onInstalled;

  const _FfmpegDialog({required this.onRetry, required this.onInstalled});

  @override
  State<_FfmpegDialog> createState() => _FfmpegDialogState();
}

class _FfmpegDialogState extends State<_FfmpegDialog> {
  bool _installing = false;

  Future<void> _install() async {
    setState(() => _installing = true);
    final ok = await FfmpegChecker.installViaBrew();
    if (!mounted) return;
    setState(() => _installing = false);
    if (ok) {
      widget.onInstalled();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось установить ffmpeg. Установите вручную: brew install ffmpeg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('FFmpeg не найден'),
      content: _installing
          ? const SizedBox(
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Установка ffmpeg через Homebrew...'),
                ],
              ),
            )
          : const Text(
              'Для конвертации необходим FFmpeg.\n\n'
              'Нажмите «Установить», чтобы автоматически установить '
              'через Homebrew.',
            ),
      actions: _installing
          ? []
          : [
              TextButton(onPressed: widget.onRetry, child: const Text('Проверить снова')),
              FilledButton(onPressed: _install, child: const Text('Установить')),
            ],
    );
  }
}
