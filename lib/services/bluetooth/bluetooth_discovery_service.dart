import 'dart:async';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import '../../features/bluetooth/domain/entities/discovered_device.dart';

class BluetoothDiscoveryService {
  BluetoothDiscoveryService([FlutterClassicBluetooth? bluetooth])
      : _bluetooth = bluetooth ?? FlutterClassicBluetooth();

  final FlutterClassicBluetooth _bluetooth;

  StreamSubscription<BtcDevice>? _resultsSub;
  StreamSubscription<bool>? _stateSub;
  bool _scanning = false;

  Future<List<DiscoveredDevice>> getPairedDevices() async {
    try {
      final devices = await _bluetooth.getPairedDevices();
      return devices.map(deviceFromPaired).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> startDiscovery({
    required void Function(DiscoveredDevice device) onDevice,
    required void Function() onCompleted,
    required void Function(Object error) onError,
  }) async {
    if (_scanning || await _bluetooth.isDiscovering()) {
      return;
    }
    _scanning = true;
    _stateSub?.cancel();
    _resultsSub?.cancel();
    _resultsSub = _bluetooth.discoveryResults.listen(
      (device) => onDevice(deviceFromDiscovery(device)),
      onError: (Object e) {
        _scanning = false;
        onError(e);
      },
    );
    _stateSub = _bluetooth.discoveryState.listen((active) {
      if (!active) {
        _scanning = false;
        onCompleted();
      }
    });
    try {
      await _bluetooth.startDiscovery();
    } catch (e) {
      await _cleanupScan();
      rethrow;
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _bluetooth.stopDiscovery();
    } catch (_) {
      // ignore stop errors; state is cleaned up below
    } finally {
      await _cleanupScan();
    }
  }

  Future<void> _cleanupScan() async {
    _scanning = false;
    await _resultsSub?.cancel();
    await _stateSub?.cancel();
    _resultsSub = null;
    _stateSub = null;
  }

  Future<void> dispose() async {
    try {
      if (_scanning || await _bluetooth.isDiscovering()) {
        await _bluetooth.stopDiscovery();
      }
    } catch (_) {
      // best-effort cleanup
    } finally {
      await _cleanupScan();
    }
  }
}
