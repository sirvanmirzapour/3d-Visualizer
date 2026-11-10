import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MagneticFieldScannerApp()));
}

class MagneticFieldScannerApp extends ConsumerWidget {
  const MagneticFieldScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Magnetic Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.root,
    );
  }
}
