import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../services/file_prefs.dart';

enum AppThemeMode { dark, light }

class SettingsState {
  final AppLocale locale;
  final AppThemeMode themeMode;
  final bool autoConnect;
  final String? lastDeviceAddress;
  final String? lastDeviceName;

  const SettingsState({
    required this.locale,
    required this.themeMode,
    this.autoConnect = false,
    this.lastDeviceAddress,
    this.lastDeviceName,
  });

  SettingsState copyWith({
    AppLocale? locale,
    AppThemeMode? themeMode,
    bool? autoConnect,
    String? lastDeviceAddress,
    String? lastDeviceName,
    bool clearLastDevice = false,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      autoConnect: autoConnect ?? this.autoConnect,
      lastDeviceAddress: clearLastDevice ? null : (lastDeviceAddress ?? this.lastDeviceAddress),
      lastDeviceName: clearLastDevice ? null : (lastDeviceName ?? this.lastDeviceName),
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController()
      : super(const SettingsState(locale: AppLocale.en, themeMode: AppThemeMode.dark));

  Future<void> load() async {
    final locale = await FilePrefs.read('locale') ?? 'en';
    final theme = await FilePrefs.read('theme') ?? 'dark';
    final auto = await FilePrefs.read('autoConnect') ?? 'false';
    final addr = await FilePrefs.read('lastDeviceAddress');
    final name = await FilePrefs.read('lastDeviceName');
    state = SettingsState(
      locale: locale == 'fa' ? AppLocale.fa : AppLocale.en,
      themeMode: theme == 'light' ? AppThemeMode.light : AppThemeMode.dark,
      autoConnect: auto == 'true',
      lastDeviceAddress: addr,
      lastDeviceName: name,
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

  Future<void> setAutoConnect(bool value) async {
    state = state.copyWith(autoConnect: value);
    await FilePrefs.write('autoConnect', value ? 'true' : 'false');
  }

  Future<void> setLastDevice(String? address, String? name) async {
    state = state.copyWith(lastDeviceAddress: address, lastDeviceName: name);
    if (address == null) {
      await FilePrefs.remove('lastDeviceAddress');
      await FilePrefs.remove('lastDeviceName');
    } else {
      await FilePrefs.write('lastDeviceAddress', address);
      if (name != null) await FilePrefs.write('lastDeviceName', name);
    }
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

final autoConnectProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).autoConnect;
});
