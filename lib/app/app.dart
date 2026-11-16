import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/navigation/nav_controller.dart';
import '../../core/settings/settings_controller.dart';
import '../../features/bluetooth/presentation/pages/bluetooth_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/scan_history/presentation/pages/history_page.dart';
import '../../features/scan_history/presentation/pages/scan_detail_page.dart';
import '../../features/live_scan/presentation/pages/live_scan_page.dart';
import '../../features/scan_config/presentation/pages/scan_configuration_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRoutes {
  static const root = '/';
  static const bluetooth = '/bluetooth';
  static const scanConfig = '/scan-config';
  static const liveScan = '/live-scan';
  static const scanDetail = '/scan-detail';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
        return MaterialPageRoute(builder: (_) => const MainNavigationShell());
      case AppRoutes.bluetooth:
        return MaterialPageRoute(builder: (_) => const BluetoothPage());
      case AppRoutes.scanConfig:
        return MaterialPageRoute(
          builder: (_) => ScanConfigurationPage(
            initialRows: (settings.arguments as Map<String, dynamic>?)?['rows'] as int?,
            initialColumns:
                (settings.arguments as Map<String, dynamic>?)?['columns'] as int?,
          ),
        );
      case AppRoutes.liveScan:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => LiveScanPage(
            rows: (args['rows'] as int?) ?? 10,
            columns: (args['columns'] as int?) ?? 10,
            zigzag: (args['zigzag'] as bool?) ?? false,
          ),
        );
      case AppRoutes.scanDetail:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => ScanDetailPage(
            title: (args['title'] as String?) ?? 'Scan Detail',
            date: (args['date'] as DateTime?) ?? DateTime.now(),
            rows: (args['rows'] as int?) ?? 0,
            columns: (args['columns'] as int?) ?? 0,
            points: (args['points'] as int?) ?? 0,
            status: (args['status'] as String?) ?? 'Incomplete',
            measurements: (args['measurements'] as List?)?.cast<num>(),
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const MainNavigationShell());
    }
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  final _pages = const [
    DashboardPage(),
    LiveScanPage.embedded(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final index = ref.watch(navControllerProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(navControllerProvider.notifier).goTo(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: Strings.tr(locale, 'dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sensors_outlined),
            selectedIcon: const Icon(Icons.sensors),
            label: Strings.tr(locale, 'liveScan'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: Strings.tr(locale, 'history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Strings.tr(locale, 'settings'),
          ),
        ],
      ),
    );
  }
}
