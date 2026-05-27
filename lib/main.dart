import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/conversion_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsProvider(prefs);

  await NotificationService.instance.init();

  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => settings),
    ],
  );

  await container.read(conversionProvider.notifier).loadHistory();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MediaConverterApp(),
    ),
  );
}
