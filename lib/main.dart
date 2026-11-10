import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MagneticFieldScannerApp()));
}

class MagneticFieldScannerApp extends StatelessWidget {
  const MagneticFieldScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magnetic Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.root,
    );
  }
}
