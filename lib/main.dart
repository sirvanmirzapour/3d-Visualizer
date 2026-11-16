import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/file_prefs.dart';
import 'core/settings/auto_connect_bootstrap.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolve the real app files directory once at startup (no extra plugin:
  // on Android the internal files dir is derived from the package name).
  try {
    final dir = Directory('/data/user/0/com.magnetic.scanner.magnetic_field_scanner/files');
    if (!await dir.exists()) await dir.create(recursive: true);
    FilePrefs.init(dir.path);
  } catch (_) {}
  runApp(const ProviderScope(child: MagneticFieldScannerApp()));
}

class MagneticFieldScannerApp extends ConsumerWidget {
  const MagneticFieldScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'GoldenMask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.root,
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          const AutoConnectBootstrap(),
        ],
      ),
    );
  }
}
