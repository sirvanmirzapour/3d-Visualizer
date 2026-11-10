import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/bluetooth/bluetooth_permission_service.dart';

final bluetoothPermissionServiceProvider =
    Provider<BluetoothPermissionService>((ref) {
  return BluetoothPermissionService();
});

// Note: we intentionally do NOT listen to adapterState() here. The plugin's
// adapterState stream emits the current state immediately on subscribe, which
// made the old invalidateSelf() pattern re-run this provider forever (perpetual
// loading). Readiness is re-evaluated on demand (e.g. refresh button / re-watch).
final bluetoothReadinessProvider =
    FutureProvider.autoDispose<BluetoothPermissionState>((ref) async {
  return ref.read(bluetoothPermissionServiceProvider).evaluate();
});
