import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

final settingsProvider = Provider<SettingsProvider>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

class SettingsProvider {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs);

  bool get notificationsEnabled =>
      _prefs.getBool(AppConstants.settingsKeyNotifications) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(AppConstants.settingsKeyNotifications, value);
  }

  String? get defaultOutputDir =>
      _prefs.getString(AppConstants.settingsKeyDefaultOutputDir);

  Future<void> setDefaultOutputDir(String path) async {
    await _prefs.setString(AppConstants.settingsKeyDefaultOutputDir, path);
  }

  bool get isDarkMode =>
      _prefs.getString(AppConstants.settingsKeyTheme) == 'dark';

  Future<void> setDarkMode(bool value) async {
    await _prefs.setString(AppConstants.settingsKeyTheme, value ? 'dark' : 'light');
  }
}
