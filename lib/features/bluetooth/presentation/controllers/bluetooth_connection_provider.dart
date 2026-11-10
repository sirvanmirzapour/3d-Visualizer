import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/bluetooth/bluetooth_connection_service.dart';

class RawDataEvent {
  final Uint8List data;
  final DateTime receivedAt;
  final int byteCount;
  final String hex;

  const RawDataEvent({
    required this.data,
    required this.receivedAt,
    required this.byteCount,
    required this.hex,
  });

  @override
  bool operator ==(Object other) =>
      other is RawDataEvent &&
      other.receivedAt == receivedAt &&
      other.hex == hex;

  @override
  int get hashCode => Object.hash(receivedAt, hex);
}

class BluetoothConnectionState {
  final BluetoothServiceStatus status;
  final String? deviceName;
  final String? deviceAddress;
  final DateTime? connectedAt;
  final DateTime? lastDataReceivedAt;
  final String? errorMessage;
  final String? errorDetails;
  final int dataEventCount;
  final int totalBytesReceived;
  final Uint8List? lastRawData;
  final List<RawDataEvent> recentEvents;
  final List<num> measurements;

  const BluetoothConnectionState({
    required this.status,
    this.deviceName,
    this.deviceAddress,
    this.connectedAt,
    this.lastDataReceivedAt,
    this.errorMessage,
    this.errorDetails,
    this.dataEventCount = 0,
    this.totalBytesReceived = 0,
    this.lastRawData,
    this.recentEvents = const [],
    this.measurements = const [],
  });

  factory BluetoothConnectionState.initial() => const BluetoothConnectionState(
        status: BluetoothServiceStatus.disconnected,
      );

  BluetoothConnectionState copyWith({
    BluetoothServiceStatus? status,
    String? deviceName,
    String? deviceAddress,
    DateTime? connectedAt,
    DateTime? lastDataReceivedAt,
    String? errorMessage,
    String? errorDetails,
    int? dataEventCount,
    int? totalBytesReceived,
    Uint8List? lastRawData,
    List<RawDataEvent>? recentEvents,
    List<num>? measurements,
    bool clearError = false,
    bool clearData = false,
  }) {
    return BluetoothConnectionState(
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      connectedAt: connectedAt ?? this.connectedAt,
      lastDataReceivedAt: lastDataReceivedAt ?? this.lastDataReceivedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorDetails: clearError ? null : (errorDetails ?? this.errorDetails),
      dataEventCount: dataEventCount ?? this.dataEventCount,
      totalBytesReceived: totalBytesReceived ?? this.totalBytesReceived,
      lastRawData: clearData ? null : (lastRawData ?? this.lastRawData),
      recentEvents: recentEvents ?? this.recentEvents,
      measurements: measurements ?? this.measurements,
    );
  }
}

class BluetoothConnectionController extends StateNotifier<BluetoothConnectionState> {
  BluetoothConnectionController(this.ref) : super(BluetoothConnectionState.initial());

  final Ref ref;
  bool _disposed = false;
  StreamSubscription<BluetoothConnectionSnapshot>? _snapshotSubscription;
  StreamSubscription<Uint8List>? _dataSubscription;

  static const int maxRecentEvents = 50;
  static const int maxMeasurements = 1500;

  String _lineBuffer = '';

  BluetoothConnectionService get _service => ref.read(bluetoothConnectionServiceProvider);

  void startListening() {
    _snapshotSubscription?.cancel();
    _dataSubscription?.cancel();
    _snapshotSubscription = _service.statusStream.listen(
      _onStatus,
      cancelOnError: false,
    );
    _dataSubscription = _service.rawDataStream.listen(
      _onData,
      cancelOnError: false,
    );
  }

  void _onStatus(BluetoothConnectionSnapshot snapshot) {
    if (_disposed) return;
    final cleared = snapshot.status == BluetoothServiceStatus.disconnected &&
        snapshot.deviceName == null &&
        snapshot.deviceAddress == null;
    if (cleared) {
      state = BluetoothConnectionState(
        status: BluetoothServiceStatus.disconnected,
        dataEventCount: state.dataEventCount,
        totalBytesReceived: state.totalBytesReceived,
        lastRawData: state.lastRawData,
        recentEvents: state.recentEvents,
        measurements: state.measurements,
      );
    } else {
      _updateState(
        status: snapshot.status,
        deviceName: snapshot.deviceName,
        deviceAddress: snapshot.deviceAddress,
        connectedAt: snapshot.connectedAt,
        lastDataReceivedAt: snapshot.lastDataReceivedAt,
        errorMessage: snapshot.errorMessage,
        errorDetails: snapshot.errorDetails,
      );
    }
  }

  void _onData(Uint8List data) {
    if (_disposed) return;
    if (state.status != BluetoothServiceStatus.connected) return;

    final measurements = <num>[...state.measurements];
    _lineBuffer += utf8.decode(data, allowMalformed: true);
    while (true) {
      final br = _indexOfLineBreak(_lineBuffer);
      if (br < 0) break;
      final raw = _lineBuffer.substring(0, br).trim();
      _lineBuffer = _lineBuffer.substring(br + 1);
      if (raw.isEmpty) continue;
      final value = num.tryParse(raw);
      if (value != null && measurements.length < maxMeasurements) {
        measurements.add(value);
      }
    }

    final now = DateTime.now();
    final event = RawDataEvent(
      data: data,
      receivedAt: now,
      byteCount: data.length,
      hex: _toHex(data),
    );
    final events = [...state.recentEvents, event];
    if (events.length > maxRecentEvents) {
      events.removeRange(0, events.length - maxRecentEvents);
    }
    _updateState(
      lastDataReceivedAt: now,
      dataEventCount: state.dataEventCount + 1,
      totalBytesReceived: state.totalBytesReceived + data.length,
      lastRawData: data,
      recentEvents: events,
      measurements: measurements,
    );
  }

  void clearMeasurements() {
    if (_disposed) return;
    _updateState(measurements: const []);
  }

  int _indexOfLineBreak(String s) {
    final n = s.indexOf('\n');
    final r = s.indexOf('\r');
    if (n < 0) return r;
    if (r < 0) return n;
    return n < r ? n : r;
  }

  void clearDebug() {
    if (_disposed) return;
    state = BluetoothConnectionState(
      status: state.status,
      deviceName: state.deviceName,
      deviceAddress: state.deviceAddress,
      connectedAt: state.connectedAt,
      lastDataReceivedAt: null,
      errorMessage: state.errorMessage,
      errorDetails: state.errorDetails,
      dataEventCount: 0,
      totalBytesReceived: 0,
      lastRawData: null,
      recentEvents: const [],
      measurements: state.measurements,
    );
  }

  Future<void> connect({
    required String address,
    String? deviceName,
  }) async {
    await _service.connect(address: address, deviceName: deviceName);
  }

  Future<void> disconnect() async {
    await _service.disconnect();
  }

  void _updateState({
    BluetoothServiceStatus? status,
    String? deviceName,
    String? deviceAddress,
    DateTime? connectedAt,
    DateTime? lastDataReceivedAt,
    String? errorMessage,
    String? errorDetails,
    int? dataEventCount,
    int? totalBytesReceived,
    Uint8List? lastRawData,
    List<RawDataEvent>? recentEvents,
    List<num>? measurements,
    bool clearError = false,
    bool clearData = false,
  }) {
    if (_disposed) return;
    final current = state;
    state = BluetoothConnectionState(
      status: status ?? current.status,
      deviceName: deviceName ?? current.deviceName,
      deviceAddress: deviceAddress ?? current.deviceAddress,
      connectedAt: connectedAt ?? current.connectedAt,
      lastDataReceivedAt: lastDataReceivedAt ?? current.lastDataReceivedAt,
      errorMessage: clearError ? null : (errorMessage ?? current.errorMessage),
      errorDetails: clearError ? null : (errorDetails ?? current.errorDetails),
      dataEventCount: dataEventCount ?? current.dataEventCount,
      totalBytesReceived: totalBytesReceived ?? current.totalBytesReceived,
      lastRawData: clearData ? null : (lastRawData ?? current.lastRawData),
      recentEvents: recentEvents ?? current.recentEvents,
      measurements: measurements ?? current.measurements,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _snapshotSubscription?.cancel();
    _dataSubscription?.cancel();
    _snapshotSubscription = null;
    _dataSubscription = null;
    super.dispose();
  }
}

String _toHex(Uint8List data) {
  final sb = StringBuffer();
  for (final byte in data) {
    if (sb.isNotEmpty) sb.write(' ');
    sb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
  }
  return sb.toString();
}

final bluetoothConnectionServiceProvider = Provider<BluetoothConnectionService>((ref) {
  final service = BluetoothConnectionService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bluetoothConnectionProvider = StateNotifierProvider<
    BluetoothConnectionController, BluetoothConnectionState>((ref) {
  final controller = BluetoothConnectionController(ref);
  controller.startListening();
  return controller;
});

final bluetoothConnectionControllerProvider = Provider<BluetoothConnectionController>((ref) {
  return ref.watch(bluetoothConnectionProvider.notifier);
});
