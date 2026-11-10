import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

/// Abstraction over a raw RFCOMM connection for testability.
abstract class BluetoothLink {
  int get id;
  String get address;
  Stream<Uint8List> get input;
  Stream<BtcConnectionState> get stateStream;
  Future<void> close();
  void dispose();
}

class _RealBluetoothLink implements BluetoothLink {
  _RealBluetoothLink(this._connection);
  final BtcConnection _connection;

  @override
  int get id => _connection.id;
  @override
  String get address => _connection.address;
  @override
  Stream<Uint8List> get input => _connection.input;
  @override
  Stream<BtcConnectionState> get stateStream => _connection.stateStream;
  @override
  Future<void> close() => _connection.close();
  @override
  void dispose() => _connection.dispose();
}

/// Transport abstraction to allow mocking without real hardware/plugin.
abstract class BluetoothConnectionTransport {
  Future<bool> isEnabled();
  Future<BtcPermissionStatus> checkPermissions();
  Future<BluetoothLink> connect({
    required String address,
    String uuid = BtcUuid.spp,
    bool secure = true,
    Duration? timeout,
  });
  Stream<BtcAdapterState> adapterState();
}

class FlutterClassicBluetoothTransport implements BluetoothConnectionTransport {
  FlutterClassicBluetoothTransport([FlutterClassicBluetooth? bluetooth])
      : _bluetooth = bluetooth ?? FlutterClassicBluetooth();

  final FlutterClassicBluetooth _bluetooth;

  @override
  Future<bool> isEnabled() => _bluetooth.isEnabled();

  @override
  Future<BtcPermissionStatus> checkPermissions() => _bluetooth.checkPermissions(
        permissions: const {BtcPermission.scan, BtcPermission.connect},
      );

  @override
  Future<BluetoothLink> connect({
    required String address,
    String uuid = BtcUuid.spp,
    bool secure = true,
    Duration? timeout,
  }) async {
    final conn = await _bluetooth.connect(
      address: address,
      uuid: uuid,
      secure: secure,
      timeout: timeout,
    );
    return _RealBluetoothLink(conn);
  }

  @override
  Stream<BtcAdapterState> adapterState() => _bluetooth.adapterState;
}
