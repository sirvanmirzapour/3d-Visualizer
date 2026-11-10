import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import 'package:magnetic_field_scanner/services/bluetooth/bluetooth_connection_service.dart';
import 'package:magnetic_field_scanner/services/bluetooth/bluetooth_connection_transport.dart';

Future<bool> waitUntil(bool Function() condition,
    {int tries = 200, Duration delay = const Duration(milliseconds: 10)}) async {
  for (var i = 0; i < tries; i++) {
    if (condition()) return true;
    await Future.delayed(delay);
  }
  return condition();
}

void main() {
  group('BluetoothConnectionService', () {
    late BluetoothConnectionService service;
    late FakeTransport transport;

    setUp(() {
      transport = FakeTransport();
      service = BluetoothConnectionService(transport);
    });

    tearDown(() {
      service.dispose();
    });

    test('successful connection becomes connected', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      service.statusStream.listen(statuses.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF', deviceName: 'HC-05');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));

      expect(service.snapshot.status, BluetoothServiceStatus.connected);
      expect(service.snapshot.deviceAddress, 'AA:BB:CC:DD:EE:FF');
      expect(service.snapshot.deviceName, 'HC-05');
    });

    test('connection failure becomes error', () async {
      transport.connectThrows = const BtcConnectionException(
        'Device unreachable',
        address: 'AA:BB:CC:DD:EE:FF',
        cause: BtcConnectFailure.unreachable,
      );
      final statuses = <BluetoothConnectionSnapshot>[];
      service.statusStream.listen(statuses.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.error));

      expect(service.snapshot.status, BluetoothServiceStatus.error);
      expect(
        service.snapshot.errorMessage,
        'The device is unreachable. Ensure HC-05 is powered on and in range.',
      );
      expect(service.snapshot.errorDetails, contains('unreachable'));
      expect(service.snapshot.deviceAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('raw data is propagated unchanged as Uint8List', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      final data = <Uint8List>[];
      service.statusStream.listen(statuses.add);
      service.rawDataStream.listen(data.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));

      final bytes = Uint8List.fromList([0x01, 0x02, 0x03, 0xFF]);
      transport.link!.addInput(bytes);
      await waitUntil(() => data.isNotEmpty);

      expect(data.first, bytes);
    });

    test('normal disconnect frees subscriptions and emits disconnected', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      service.statusStream.listen(statuses.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));

      service.disconnect();
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.disconnected));

      expect(service.snapshot.status, BluetoothServiceStatus.disconnected);
      expect(service.hasActiveLink, isFalse);
      expect(service.isConnected, isFalse);
      expect(transport.link!.disposed, isTrue);
    });

    test('remote disconnect emits disconnected and frees subscriptions', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      service.statusStream.listen(statuses.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));

      transport.link!.addState(BtcConnectionState.disconnected);
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.disconnected));

      expect(service.hasActiveLink, isFalse);
      expect(service.isConnected, isFalse);
      expect(transport.link!.disposed, isTrue);
    });

    test('second connect while connected is ignored', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      service.statusStream.listen(statuses.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));

      await service.connect(address: '00:11:22:33:44:55');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.snapshot.deviceAddress, 'AA:BB:CC:DD:EE:FF');
      expect(transport.link!.address, 'AA:BB:CC:DD:EE:FF');
    });

    test('no data is propagated after disconnect', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      final data = <Uint8List>[];
      service.statusStream.listen(statuses.add);
      service.rawDataStream.listen(data.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));

      service.disconnect();
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.disconnected));

      transport.link!.addInput(Uint8List.fromList([0xAA, 0xBB]));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(data, isEmpty);
    });

    test('subscriptions are cancelled on disconnect', () async {
      final statuses = <BluetoothConnectionSnapshot>[];
      final data = <Uint8List>[];
      service.statusStream.listen(statuses.add);
      service.rawDataStream.listen(data.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.connected));
      final before = statuses.length;

      service.disconnect();
      await waitUntil(() => statuses.length > before);

      transport.link!.addInput(Uint8List.fromList([0x01]));
      transport.link!.addState(BtcConnectionState.connected);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(data, isEmpty);
    });

    test('snapshot holds error fields after failure', () async {
      transport.connectThrows = const BtcConnectionException(
        'Device unreachable',
        address: 'AA:BB:CC:DD:EE:FF',
        cause: BtcConnectFailure.unreachable,
      );
      final statuses = <BluetoothConnectionSnapshot>[];
      service.statusStream.listen(statuses.add);

      service.connect(address: 'AA:BB:CC:DD:EE:FF');
      await waitUntil(() => statuses.any((s) => s.status == BluetoothServiceStatus.error));

      final error = statuses.lastWhere((s) => s.status == BluetoothServiceStatus.error);
      expect(error.errorMessage, isNotEmpty);
      expect(error.errorDetails, isNotEmpty);
      expect(error.deviceAddress, 'AA:BB:CC:DD:EE:FF');
    });
  });
}

class FakeBluetoothLink implements BluetoothLink {
  FakeBluetoothLink() {
    _inputController = StreamController<Uint8List>.broadcast();
    _stateController = StreamController<BtcConnectionState>.broadcast();
  }

  @override
  int id = 1;

  @override
  String address = 'AA:BB:CC:DD:EE:FF';

  @override
  Stream<Uint8List> get input => _inputController.stream;

  @override
  Stream<BtcConnectionState> get stateStream => _stateController.stream;

  @override
  Future<void> close() async {
    await _inputController.close();
    await _stateController.close();
  }

  @override
  void dispose() {
    disposed = true;
  }

  bool disposed = false;

  late final StreamController<Uint8List> _inputController;
  late final StreamController<BtcConnectionState> _stateController;

  void addInput(Uint8List data) {
    if (_inputController.isClosed) return;
    _inputController.add(data);
  }

  void addState(BtcConnectionState state) {
    if (_stateController.isClosed) return;
    _stateController.add(state);
  }
}

class FakeTransport implements BluetoothConnectionTransport {
  FakeTransport() {
    _adapterController = StreamController<BtcAdapterState>.broadcast();
  }

  @override
  Stream<BtcAdapterState> adapterState() => _adapterController.stream;

  @override
  Future<bool> isEnabled() => Future.value(true);

  @override
  Future<BtcPermissionStatus> checkPermissions() async => BtcPermissionStatus.granted;

  @override
  Future<BluetoothLink> connect({
    required String address,
    String uuid = BtcUuid.spp,
    bool secure = true,
    Duration? timeout,
  }) async {
    if (connectThrows != null) throw connectThrows!;
    final link = FakeBluetoothLink();
    link.address = address;
    _link = link;
    return link;
  }

  late final StreamController<BtcAdapterState> _adapterController;

  FakeBluetoothLink? _link;

  Object? connectThrows;

  FakeBluetoothLink? get link => _link;
}
