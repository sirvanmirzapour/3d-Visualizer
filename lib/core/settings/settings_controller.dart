import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../services/file_prefs.dart';

enum AppThemeMode { dark, light }

class SettingsState {
  final AppLocale locale;
  final AppThemeMode themeMode;

  const SettingsState({required this.locale, required this.themeMode});

  SettingsState copyWith({AppLocale? locale, AppThemeMode? themeMode}) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState(locale: AppLocale.en, themeMode: AppThemeMode.dark));

  Future<void> load() async {
    final locale = await FilePrefs.read('locale') ?? 'en';
    final theme = await FilePrefs.read('theme') ?? 'dark';
    state = SettingsState(
      locale: locale == 'fa' ? AppLocale.fa : AppLocale.en,
      themeMode: theme == 'light' ? AppThemeMode.light : AppThemeMode.dark,
    );
  }

  Future<void> setLocale(AppLocale locale) async {
    state = state.copyWith(locale: locale);
    await FilePrefs.write('locale', locale == AppLocale.fa ? 'fa' : 'en');
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await FilePrefs.write('theme', mode == AppThemeMode.light ? 'light' : 'dark');
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final controller = SettingsController();
  controller.load();
  return controller;
});

final localeProvider = Provider<AppLocale>((ref) {
  return ref.watch(settingsProvider).locale;
});

final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
