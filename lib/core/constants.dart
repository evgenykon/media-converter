import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Media Converter';
  static const String historyFileName = 'conversion_history.json';
  static const String settingsKeyNotifications = 'notifications_enabled';
  static const String settingsKeyTheme = 'theme_mode';
  static const String settingsKeyDefaultOutputDir = 'default_output_dir';
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4),
    brightness: Brightness.light,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4),
    brightness: Brightness.dark,
  );
}
