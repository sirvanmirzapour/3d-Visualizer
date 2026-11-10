import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:magnetic_field_scanner/features/bluetooth/presentation/controllers/bluetooth_connection_provider.dart';
import 'package:magnetic_field_scanner/services/bluetooth/bluetooth_connection_service.dart';
import 'package:magnetic_field_scanner/services/bluetooth/bluetooth_connection_transport.dart';

void main() {
  final containers = <ProviderContainer>[];

  ProviderContainer createContainer([FakeTransport? transport]) {
    final container = ProviderContainer(
      overrides: [
        bluetoothConnectionServiceProvider.overrideWithValue(
          BluetoothConnectionService(transport ?? FakeTransport()),
        ),
      ],
    );
    containers.add(container);
    return container;
  }

  void disposeContainer(ProviderContainer container) {
    containers.remove(container);
    container.dispose();
  }

  tearDown(() {
    for (final c in List.of(containers)) {
      c.dispose();
    }
    containers.clear();
  });

  BluetoothConnectionController controllerOf(ProviderContainer container) =>
      container.read(bluetoothConnectionProvider.notifier);

  group('BluetoothConnectionController', () {
    test('initial state is disconnected', () {
      final controller = controllerOf(createContainer());
      expect(controller.state.status, BluetoothServiceStatus.disconnected);
      expect(controller.state.dataEventCount, 0);
      expect(controller.state.lastRawData, isNull);
      expect(controller.state.recentEvents, isEmpty);
    });

    test('successful connect transitions connecting -> connected', () async {
      final controller = controllerOf(createContainer());

      controller.connect(address: 'AA:BB:CC:DD:EE:FF', deviceName: 'HC-05');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state.status, BluetoothServiceStatus.connected);
      expect(controller.state.deviceAddress, 'AA:BB:CC:DD:EE:FF');
      expect(controller.state.deviceName, 'HC-05');
      expect(controller.state.connectedAt, isNotNull);
    });

    test('failed connect emits error state', () async {
      final transport = FakeTransport()
        ..connectThrows = const BtcConnectionException(
          'Device unreachable',
          address: 'AA:BB:CC:DD:EE:FF',
          cause: BtcConnectFailure.unreachable,
        );
      final controller = controllerOf(createContainer(transport));

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state.status, BluetoothServiceStatus.error);
      expect(controller.state.errorMessage, isNotEmpty);
      expect(controller.state.errorDetails, contains('unreachable'));
    });

    test('disconnect returns to disconnected and clears connection info', () async {
      final controller = controllerOf(createContainer());

      controller.connect(address: 'AA:BB:CC:DD:EE:FF', deviceName: 'HC-05');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state.status, BluetoothServiceStatus.connected);

      controller.disconnect();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state.status, BluetoothServiceStatus.disconnected);
      expect(controller.state.deviceAddress, isNull);
      expect(controller.state.connectedAt, isNull);
    });

    test('raw data is recorded with count, time, bytes and hex', () async {
      final transport = FakeTransport();
      final controller = controllerOf(createContainer(transport));

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));

      transport.link!.addInput(Uint8List.fromList([0x01, 0x02, 0xFF]));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.dataEventCount, 1);
      expect(controller.state.lastDataReceivedAt, isNotNull);
      expect(controller.state.lastRawData, Uint8List.fromList([0x01, 0x02, 0xFF]));
      expect(controller.state.recentEvents.length, 1);
      expect(controller.state.recentEvents.first.byteCount, 3);
      expect(controller.state.recentEvents.first.hex, '01 02 FF');

      transport.link!.addInput(Uint8List.fromList([0xAA]));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.dataEventCount, 2);
      expect(controller.state.recentEvents.length, 2);
    });

    test('parses line-based ASCII measurements across chunk boundaries', () async {
      final transport = FakeTransport();
      final controller = controllerOf(createContainer(transport));

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));

      transport.link!.addInput(Uint8List.fromList('123\r\n'.codeUnits));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.measurements, [123]);

      transport.link!.addInput(Uint8List.fromList('45'.codeUnits));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.measurements, [123]);

      transport.link!.addInput(Uint8List.fromList('6\n'.codeUnits));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.measurements, [123, 456]);
    });

    test('recent events buffer is bounded to maxRecentEvents', () async {
      final transport = FakeTransport();
      final controller = controllerOf(createContainer(transport));

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));

      for (var i = 0; i < 60; i++) {
        transport.link!.addInput(Uint8List.fromList([i & 0xFF]));
      }
      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.state.dataEventCount, 60);
      expect(controller.state.recentEvents.length, BluetoothConnectionController.maxRecentEvents);
      expect(controller.state.recentEvents.first.hex, '0A');
      expect(controller.state.recentEvents.last.hex, '3B');
    });

    test('sudden remote disconnect returns state to disconnected', () async {
      final transport = FakeTransport();
      final controller = controllerOf(createContainer(transport));

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state.status, BluetoothServiceStatus.connected);

      transport.link!.addState(BtcConnectionState.disconnected);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.status, BluetoothServiceStatus.disconnected);
    });

    test('concurrent connect is ignored', () async {
      final transport = FakeTransport();
      final controller = controllerOf(createContainer(transport));

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));

      controller.connect(address: '00:11:22:33:44:55');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state.deviceAddress, 'AA:BB:CC:DD:EE:FF');
      expect(transport.link!.address, 'AA:BB:CC:DD:EE:FF');
    });

    test('state is not updated after dispose', () async {
      final transport = FakeTransport();
      final container = createContainer(transport);
      final controller = controllerOf(container);

      var events = 0;
      container.listen(bluetoothConnectionProvider, (_, _) => events++);

      controller.connect(address: 'AA:BB:CC:DD:EE:FF');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state.status, BluetoothServiceStatus.connected);
      expect(events, greaterThan(0));

      disposeContainer(container);
      final snapshot = events;

      transport.link!.addInput(Uint8List.fromList([0x01]));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(events, snapshot);
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

  void addInput(Uint8List data) => _inputController.add(data);

  void addState(BtcConnectionState state) => _stateController.add(state);
}

class FakeTransport implements BluetoothConnectionTransport {
  @override
  Stream<BtcAdapterState> adapterState() => const Stream.empty();

  @override
  Future<bool> isEnabled() async => true;

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

  Object? connectThrows;

  FakeBluetoothLink? _link;

  FakeBluetoothLink? get link => _link;
}
