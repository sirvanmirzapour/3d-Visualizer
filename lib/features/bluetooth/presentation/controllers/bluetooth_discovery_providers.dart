import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/bluetooth/bluetooth_discovery_service.dart';
import '../../domain/entities/discovered_device.dart';
import 'bluetooth_permission_providers.dart';

enum DiscoveryStatus { idle, scanning, scanCompleted, error }

class BluetoothDiscoveryState {
  final DiscoveryStatus status;
  final List<DiscoveredDevice> pairedDevices;
  final List<DiscoveredDevice> discoveredDevices;
  final String? message;

  const BluetoothDiscoveryState({
    required this.status,
    required this.pairedDevices,
    required this.discoveredDevices,
    this.message,
  });

  factory BluetoothDiscoveryState.initial() => const BluetoothDiscoveryState(
        status: DiscoveryStatus.idle,
        pairedDevices: [],
        discoveredDevices: [],
      );

  BluetoothDiscoveryState copyWith({
    DiscoveryStatus? status,
    List<DiscoveredDevice>? pairedDevices,
    List<DiscoveredDevice>? discoveredDevices,
    String? message,
    bool clearMessage = false,
  }) {
    return BluetoothDiscoveryState(
      status: status ?? this.status,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final bluetoothDiscoveryServiceProvider =
    Provider<BluetoothDiscoveryService>((ref) {
  final service = BluetoothDiscoveryService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class BluetoothDiscoveryController extends StateNotifier<BluetoothDiscoveryState> {
  BluetoothDiscoveryController(this.ref) : super(BluetoothDiscoveryState.initial());

  final Ref ref;
  bool _disposed = false;

  BluetoothDiscoveryService get _service => ref.read(bluetoothDiscoveryServiceProvider);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadPairedDevices() async {
    try {
      final devices = await _service.getPairedDevices();
      if (_disposed) return;
      final merged = mergeDevices(state.pairedDevices, devices);
      final paired = merged.where((d) => d.isPaired).toList();
      final discovered = merged.where((d) => !d.isPaired).toList();
      state = state.copyWith(
        pairedDevices: paired,
        discoveredDevices: discovered,
        clearMessage: state.status != DiscoveryStatus.error,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        status: DiscoveryStatus.error,
        message: _mapError(e),
      );
    }
  }

  Future<void> startScan() async {
    if (state.status == DiscoveryStatus.scanning) return;

    final readiness = ref.read(bluetoothReadinessProvider).asData?.value;
    if (readiness == null || !readiness.canScan) {
      state = state.copyWith(
        status: DiscoveryStatus.error,
        message: readiness?.message ??
            'Bluetooth is not ready. Check permissions and adapter state.',
      );
      return;
    }

    // Refresh paired devices and clear previous discovered results.
    List<DiscoveredDevice> paired = state.pairedDevices;
    try {
      paired = await _service.getPairedDevices();
    } catch (_) {
      // keep existing paired list on refresh failure
    }
    if (_disposed) return;
    state = state.copyWith(
      status: DiscoveryStatus.scanning,
      pairedDevices: mergeDevices(const [], paired).where((d) => d.isPaired).toList(),
      discoveredDevices: const [],
      clearMessage: true,
    );

    try {
      await _service.startDiscovery(
        onDevice: (device) {
          if (_disposed) return;
          final pairedAddresses = state.pairedDevices.map((d) => d.address).toSet();
          final incoming = pairedAddresses.contains(device.address)
              ? device.copyWith(isPaired: true, source: DiscoverySource.paired)
              : device;
          final all = mergeDevices([
            ...state.pairedDevices,
            ...state.discoveredDevices,
          ], [incoming]);
          state = state.copyWith(
            pairedDevices: all.where((d) => d.isPaired).toList(),
            discoveredDevices: all.where((d) => !d.isPaired).toList(),
          );
        },
        onCompleted: () {
          if (_disposed) return;
          if (state.status == DiscoveryStatus.scanning) {
            state = state.copyWith(status: DiscoveryStatus.scanCompleted);
          }
        },
        onError: (e) {
          if (_disposed) return;
          state = state.copyWith(
            status: DiscoveryStatus.error,
            message: _mapError(e),
          );
        },
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        status: DiscoveryStatus.error,
        message: _mapError(e),
      );
    }
  }

  Future<void> stopScan() async {
    await _service.stopDiscovery();
    if (_disposed) return;
    if (state.status == DiscoveryStatus.scanning) {
      state = state.copyWith(status: DiscoveryStatus.scanCompleted);
    }
  }

  void clearError() {
    if (state.status == DiscoveryStatus.error) {
      state = state.copyWith(status: DiscoveryStatus.idle, clearMessage: true);
    }
  }

  String _mapError(Object e) {
    if (e is BtcPermissionException) {
      return 'Bluetooth permission is missing. Please grant permissions and try again.';
    }
    if (e is BtcDisabledException) {
      return 'Bluetooth is turned off. Turn it on to scan for devices.';
    }
    if (e is BtcDiscoveryException) {
      return e.message;
    }
    if (e is BtcUnsupportedException) {
      return 'Bluetooth discovery is not supported on this platform/device.';
    }
    if (e is BtcException) {
      return e.message;
    }
    return 'Discovery failed: $e';
  }
}

final bluetoothDiscoveryProvider = StateNotifierProvider.autoDispose<
    BluetoothDiscoveryController, BluetoothDiscoveryState>((ref) {
  final controller = BluetoothDiscoveryController(ref);
  ref.onDispose(() {
    controller.stopScan();
  });
  return controller;
});
