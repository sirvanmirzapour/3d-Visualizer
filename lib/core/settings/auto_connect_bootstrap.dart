import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bluetooth/presentation/controllers/bluetooth_connection_provider.dart';
import '../../features/bluetooth/presentation/controllers/bluetooth_permission_providers.dart';
import '../../services/bluetooth/bluetooth_connection_service.dart';
import 'settings_controller.dart';

/// Listens for readiness and auto-connect preference, then reconnects to the
/// last device when the adapter becomes ready.
class AutoConnectBootstrap extends ConsumerStatefulWidget {
  const AutoConnectBootstrap({super.key});

  @override
  ConsumerState<AutoConnectBootstrap> createState() => _AutoConnectBootstrapState();
}

class _AutoConnectBootstrapState extends ConsumerState<AutoConnectBootstrap> {
  bool _attempted = false;

  Future<void> _tryAutoConnect() async {
    if (_attempted) return;
    final settings = ref.read(settingsProvider);
    if (!settings.autoConnect || settings.lastDeviceAddress == null) return;

    final readiness = ref.read(bluetoothReadinessProvider).asData?.value;
    if (readiness == null || !readiness.canScan) return;

    final conn = ref.read(bluetoothConnectionProvider);
    if (conn.status == BluetoothServiceStatus.connected ||
        conn.status == BluetoothServiceStatus.connecting) {
      return;
    }

    _attempted = true;
    await ref.read(bluetoothConnectionProvider.notifier).connect(
          address: settings.lastDeviceAddress!,
          deviceName: settings.lastDeviceName,
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoConnect());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bluetoothReadinessProvider, (prev, next) {
      final value = next.asData?.value;
      if (value != null && value.canScan) _tryAutoConnect();
    });
    ref.listen(settingsProvider, (prev, next) {
      if (next.autoConnect) {
        _attempted = false;
        _tryAutoConnect();
      }
    });
    return const SizedBox.shrink();
  }
}
