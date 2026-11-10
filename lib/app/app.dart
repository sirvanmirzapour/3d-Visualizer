import 'package:flutter/material.dart';

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
          ),
        );
      case AppRoutes.scanDetail:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => ScanDetailPage(
            title: (args['title'] as String?) ?? 'Scan Detail',
            date: (args['date'] as String?) ?? '-',
            rows: (args['rows'] as int?) ?? 0,
            columns: (args['columns'] as int?) ?? 0,
            points: (args['points'] as int?) ?? 0,
            status: (args['status'] as String?) ?? 'Incomplete',
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const MainNavigationShell());
    }
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    LiveScanPage.embedded(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Live Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
