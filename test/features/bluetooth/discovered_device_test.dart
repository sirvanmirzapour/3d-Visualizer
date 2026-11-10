import 'package:flutter_test/flutter_test.dart';
import 'package:magnetic_field_scanner/features/bluetooth/domain/entities/discovered_device.dart';

void main() {
  group('displayDeviceName', () {
    test('returns alias or name', () {
      expect(displayDeviceName('HC-05', null), 'HC-05');
      expect(displayDeviceName('HC-05', 'Sensor'), 'Sensor');
    });
    test('returns Unknown Device for empty/null', () {
      expect(displayDeviceName(null, null), 'Unknown Device');
      expect(displayDeviceName('', null), 'Unknown Device');
      expect(displayDeviceName('  ', null), 'Unknown Device');
    });
  });

  group('mergeDevices', () {
    test('deduplicates by address', () {
      final a = const DiscoveredDevice(
        name: 'HC-05', address: 'AA:BB', isPaired: false, source: DiscoverySource.discovered);
      final b = const DiscoveredDevice(
        name: 'HC-05', address: 'AA:BB', isPaired: false, source: DiscoverySource.discovered, rssi: -40);
      final merged = mergeDevices([a], [b]);
      expect(merged.length, 1);
      expect(merged.first.rssi, -40);
    });

    test('keeps paired status when discovered again', () {
      final paired = const DiscoveredDevice(
        name: 'HC-05', address: 'AA:BB', isPaired: true, source: DiscoverySource.paired);
      final disc = const DiscoveredDevice(
        name: 'HC-05', address: 'AA:BB', isPaired: false, source: DiscoverySource.discovered);
      final merged = mergeDevices([paired], [disc]);
      expect(merged.length, 1);
      expect(merged.first.isPaired, true);
      expect(merged.first.source, DiscoverySource.paired);
    });

    test('prefers real name over Unknown Device', () {
      final u = const DiscoveredDevice(
        name: 'Unknown Device', address: 'AA:BB', isPaired: false, source: DiscoverySource.discovered);
      final n = const DiscoveredDevice(
        name: 'MySensor', address: 'AA:BB', isPaired: false, source: DiscoverySource.discovered);
      final merged = mergeDevices([u], [n]);
      expect(merged.first.name, 'MySensor');
    });

    test('sorts paired before discovered', () {
      final d = const DiscoveredDevice(
        name: 'Zed', address: '11', isPaired: false, source: DiscoverySource.discovered);
      final p = const DiscoveredDevice(
        name: 'Alpha', address: '22', isPaired: true, source: DiscoverySource.paired);
      final merged = mergeDevices([d], [p]);
      expect(merged.first.isPaired, true);
    });
  });
}
