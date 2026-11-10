import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import 'bluetooth_connection_transport.dart';

enum BluetoothServiceStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class BluetoothConnectionSnapshot {
  final BluetoothServiceStatus status;
  final String? deviceName;
  final String? deviceAddress;
  final DateTime? connectedAt;
  final DateTime? lastDataReceivedAt;
  final String? errorMessage;
  final String? errorDetails;

  const BluetoothConnectionSnapshot({
    required this.status,
    this.deviceName,
    this.deviceAddress,
    this.connectedAt,
    this.lastDataReceivedAt,
    this.errorMessage,
    this.errorDetails,
  });

  factory BluetoothConnectionSnapshot.disconnected() =>
      const BluetoothConnectionSnapshot(status: BluetoothServiceStatus.disconnected);

  BluetoothConnectionSnapshot copyWith({
    BluetoothServiceStatus? status,
    String? deviceName,
    String? deviceAddress,
    DateTime? connectedAt,
    DateTime? lastDataReceivedAt,
    String? errorMessage,
    String? errorDetails,
    bool clearDevice = false,
    bool clearError = false,
    bool clearConnectedAt = false,
  }) {
    return BluetoothConnectionSnapshot(
      status: status ?? this.status,
      deviceName: clearDevice ? null : (deviceName ?? this.deviceName),
      deviceAddress: clearDevice ? null : (deviceAddress ?? this.deviceAddress),
      connectedAt: clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      lastDataReceivedAt: lastDataReceivedAt ?? this.lastDataReceivedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorDetails: clearError ? null : (errorDetails ?? this.errorDetails),
    );
  }
}

class BluetoothConnectionService {
  BluetoothConnectionService([BluetoothConnectionTransport? transport])
      : _transport = transport ?? FlutterClassicBluetoothTransport();

  final BluetoothConnectionTransport _transport;

  final _statusController = StreamController<BluetoothConnectionSnapshot>.broadcast();
  final _dataController = StreamController<Uint8List>.broadcast();

  BluetoothConnectionSnapshot _snapshot = BluetoothConnectionSnapshot.disconnected();
  BluetoothLink? _link;
  StreamSubscription<Uint8List>? _inputSub;
  StreamSubscription<BtcConnectionState>? _stateSub;
  bool _cleaning = false;
  int _connectGeneration = 0;

  Stream<BluetoothConnectionSnapshot> get statusStream => _statusController.stream;
  Stream<Uint8List> get rawDataStream => _dataController.stream;
  BluetoothConnectionSnapshot get snapshot => _snapshot;

  bool get isConnected => _snapshot.status == BluetoothServiceStatus.connected;
  bool get isConnecting => _snapshot.status == BluetoothServiceStatus.connecting;
  bool get hasActiveLink => _link != null;

  void _emit(BluetoothConnectionSnapshot next) {
    _snapshot = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  Future<void> connect({
    required String address,
    String? deviceName,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_snapshot.status == BluetoothServiceStatus.connecting ||
        _snapshot.status == BluetoothServiceStatus.connected ||
        _snapshot.status == BluetoothServiceStatus.disconnecting ||
        _link != null) {
      // Prevent concurrent/overlapping connections.
      if (_snapshot.status == BluetoothServiceStatus.connecting) return;
      if (_snapshot.status == BluetoothServiceStatus.disconnecting) return;
      if (_link != null || isConnected) return;
    }

    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      _emit(_snapshot.copyWith(
        status: BluetoothServiceStatus.error,
        errorMessage: 'Invalid device address.',
        errorDetails: 'Address is empty.',
      ));
      return;
    }

    try {
      final enabled = await _transport.isEnabled();
      if (!enabled) {
        _emit(_snapshot.copyWith(
          status: BluetoothServiceStatus.error,
          deviceName: deviceName,
          deviceAddress: trimmed,
          errorMessage: 'Bluetooth is turned off.',
          errorDetails: 'adapterOff',
        ));
        return;
      }
      final perm = await _transport.checkPermissions();
      if (perm == BtcPermissionStatus.denied ||
          perm == BtcPermissionStatus.permanentlyDenied) {
        _emit(_snapshot.copyWith(
          status: BluetoothServiceStatus.error,
          deviceName: deviceName,
          deviceAddress: trimmed,
          errorMessage: 'Bluetooth permission is required to connect.',
          errorDetails: perm.name,
        ));
        return;
      }
    } catch (e) {
      _emit(_snapshot.copyWith(
        status: BluetoothServiceStatus.error,
        deviceName: deviceName,
        deviceAddress: trimmed,
        errorMessage: 'Failed to verify Bluetooth prerequisites.',
        errorDetails: e.toString(),
      ));
      return;
    }

    final gen = ++_connectGeneration;
    _emit(BluetoothConnectionSnapshot(
      status: BluetoothServiceStatus.connecting,
      deviceName: deviceName,
      deviceAddress: trimmed,
    ));

    BluetoothLink? link;
    try {
      link = await _transport.connect(
        address: trimmed,
        uuid: BtcUuid.spp,
        timeout: timeout,
      );
      // If a disconnect/cancel happened during connect, or a newer attempt started.
      if (gen != _connectGeneration ||
          _snapshot.status == BluetoothServiceStatus.disconnecting) {
        try { await link.close(); } catch (_) {}
        link.dispose();
        if (gen == _connectGeneration &&
            _snapshot.status == BluetoothServiceStatus.disconnecting) {
          await _finalizeDisconnect(notify: true);
        }
        return;
      }
      _attachLink(link, deviceName: deviceName, address: trimmed);
    } catch (e) {
      // stale attempt
      if (gen != _connectGeneration) return;
      try { link?.dispose(); } catch (_) {}
      _link = null;
      _emit(BluetoothConnectionSnapshot(
        status: BluetoothServiceStatus.error,
        deviceName: deviceName,
        deviceAddress: trimmed,
        errorMessage: _userMessageForError(e),
        errorDetails: _detailsForError(e),
      ));
    }
  }

  void _attachLink(BluetoothLink link, {String? deviceName, required String address}) {
    _link = link;
    _inputSub = link.input.listen(
      (data) {
        if (_snapshot.status != BluetoothServiceStatus.connected) return;
        _emit(_snapshot.copyWith(lastDataReceivedAt: DateTime.now()));
        if (!_dataController.isClosed) _dataController.add(data);
      },
      onError: (Object e, StackTrace st) {
        _handleLinkFailure(_userMessageForError(e), _detailsForError(e));
      },
      cancelOnError: false,
    );
    _stateSub = link.stateStream.listen(
      (state) {
        if (state == BtcConnectionState.disconnected) {
          // Remote/underlying disconnect.
          _handleRemoteDisconnected();
        } else if (state == BtcConnectionState.connecting) {
          if (_snapshot.status != BluetoothServiceStatus.disconnecting) {
            _emit(_snapshot.copyWith(status: BluetoothServiceStatus.connecting));
          }
        } else if (state == BtcConnectionState.connected) {
          if (_snapshot.status != BluetoothServiceStatus.disconnecting) {
            _emit(_snapshot.copyWith(status: BluetoothServiceStatus.connected));
          }
        } else if (state == BtcConnectionState.disconnecting) {
          if (_snapshot.status == BluetoothServiceStatus.connected ||
              _snapshot.status == BluetoothServiceStatus.connecting) {
            _emit(_snapshot.copyWith(status: BluetoothServiceStatus.disconnecting));
          }
        }
      },
      onError: (Object e, StackTrace st) {
        _handleLinkFailure(_userMessageForError(e), _detailsForError(e));
      },
      cancelOnError: false,
    );

    _emit(BluetoothConnectionSnapshot(
      status: BluetoothServiceStatus.connected,
      deviceName: deviceName,
      deviceAddress: address,
      connectedAt: DateTime.now(),
    ));
  }

  Future<void> disconnect() async {
    if (_snapshot.status == BluetoothServiceStatus.disconnected && _link == null) {
      return;
    }
    if (_snapshot.status == BluetoothServiceStatus.disconnecting) {
      return;
    }
    final genAtRequest = _connectGeneration;
    if (_snapshot.status == BluetoothServiceStatus.connecting && _link == null) {
      // Mark intent; connect() will close the link if it arrives later.
      _emit(_snapshot.copyWith(status: BluetoothServiceStatus.disconnecting, clearError: true));
      // If connect never yields, finalize after a short guard.
      Future<void>.delayed(const Duration(milliseconds: 50), () async {
        if (_connectGeneration == genAtRequest &&
            _snapshot.status == BluetoothServiceStatus.disconnecting &&
            _link == null) {
          await _finalizeDisconnect();
        }
      });
      return;
    }
    _emit(_snapshot.copyWith(status: BluetoothServiceStatus.disconnecting, clearError: true));
    final link = _link;
    await _cancelSubscriptions();
    if (link != null) {
      try {
        await link.close();
      } catch (_) {
        // best-effort; still finalize cleanup
      }
      try { link.dispose(); } catch (_) {}
    }
    _link = null;
    await _finalizeDisconnect();
  }

  void _handleRemoteDisconnected() {
    if (_cleaning) return;
    _cleanupLinkResources();
    _emit(BluetoothConnectionSnapshot.disconnected());
  }

  void _handleLinkFailure(String message, String details) {
    if (_cleaning) return;
    final name = _snapshot.deviceName;
    final addr = _snapshot.deviceAddress;
    _cleanupLinkResources();
    _emit(BluetoothConnectionSnapshot(
      status: BluetoothServiceStatus.error,
      deviceName: name,
      deviceAddress: addr,
      errorMessage: message,
      errorDetails: details,
    ));
  }

  void _cleanupLinkResources() {
    if (_cleaning) return;
    _cleaning = true;
    try {
      _inputSub?.cancel();
      _stateSub?.cancel();
      _inputSub = null;
      _stateSub = null;
      try { _link?.dispose(); } catch (_) {}
      _link = null;
    } finally {
      _cleaning = false;
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _inputSub?.cancel();
    await _stateSub?.cancel();
    _inputSub = null;
    _stateSub = null;
  }

  Future<void> _finalizeDisconnect({bool notify = true}) async {
    _cleanupLinkResources();
    if (notify) {
      _emit(BluetoothConnectionSnapshot.disconnected());
    } else {
      _snapshot = BluetoothConnectionSnapshot.disconnected();
    }
  }

  String _userMessageForError(Object e) {
    if (e is BtcConnectionException) {
      switch (e.cause) {
        case BtcConnectFailure.adapterOff:
          return 'Bluetooth is turned off.';
        case BtcConnectFailure.notPaired:
          return 'The device is not paired. Pair it in Android Bluetooth settings, then try again.';
        case BtcConnectFailure.permissionDenied:
          return 'Bluetooth permission was denied.';
        case BtcConnectFailure.unreachable:
          return 'The device is unreachable. Ensure HC-05 is powered on and in range.';
        case BtcConnectFailure.serviceNotSupported:
          return 'The requested serial service is not supported by this device.';
        case BtcConnectFailure.busy:
          return 'The device or Bluetooth channel is busy. Try again.';
        case BtcConnectFailure.timeout:
          return 'Connection attempt timed out.';
        case BtcConnectFailure.unknown:
          return e.message.isNotEmpty ? e.message : 'Connection failed.';
      }
    }
    if (e is BtcTimeoutException) return 'Connection attempt timed out.';
    if (e is BtcPermissionException) return 'Bluetooth permission was denied.';
    if (e is BtcDisabledException) return 'Bluetooth is turned off.';
    if (e is BtcAddressException) return 'Invalid Bluetooth device address.';
    if (e is BtcUnsupportedException) return 'Bluetooth Classic is not supported on this device.';
    if (e is BtcException) return e.message.isNotEmpty ? e.message : 'Bluetooth error.';
    return 'Unexpected Bluetooth error.';
  }

  String _detailsForError(Object e) {
    if (e is BtcConnectionException) {
      return 'BtcConnectionException(cause=${e.cause.name}, code=${e.code}, address=${e.address}, message=${e.message})';
    }
    if (e is BtcException) {
      return '${e.runtimeType}(code=${e.code}, message=${e.message})';
    }
    return e.toString();
  }

  Future<void> dispose() async {
    _connectGeneration++;
    await disconnect();
    await _statusController.close();
    await _dataController.close();
  }
}
