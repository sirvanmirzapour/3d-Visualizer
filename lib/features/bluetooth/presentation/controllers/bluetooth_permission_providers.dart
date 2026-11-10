import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/bluetooth/bluetooth_permission_service.dart';

final bluetoothPermissionServiceProvider =
    Provider<BluetoothPermissionService>((ref) {
  return BluetoothPermissionService();
});

final bluetoothReadinessProvider =
    FutureProvider.autoDispose<BluetoothPermissionState>((ref) async {
  final service = ref.watch(bluetoothPermissionServiceProvider);
  final sub = service.adapterState().listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  return service.evaluate();
});
