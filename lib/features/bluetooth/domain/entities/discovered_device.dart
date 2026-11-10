import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

enum DiscoverySource { paired, discovered }

class DiscoveredDevice {
  final String name;
  final String address;
  final bool isPaired;
  final DiscoverySource source;
  final int? rssi;

  const DiscoveredDevice({
    required this.name,
    required this.address,
    required this.isPaired,
    required this.source,
    this.rssi,
  });

  DiscoveredDevice copyWith({
    String? name,
    String? address,
    bool? isPaired,
    DiscoverySource? source,
    int? rssi,
  }) {
    return DiscoveredDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      isPaired: isPaired ?? this.isPaired,
      source: source ?? this.source,
      rssi: rssi ?? this.rssi,
    );
  }
}

String displayDeviceName(String? name, String? alias) {
  final value = alias ?? name;
  if (value == null || value.trim().isEmpty) return 'Unknown Device';
  return value.trim();
}

DiscoveredDevice deviceFromPaired(BtcDevice device) {
  return DiscoveredDevice(
    name: displayDeviceName(device.name, device.alias),
    address: device.address,
    isPaired: device.bondState == BtcBondState.bonded || true,
    source: DiscoverySource.paired,
    rssi: device.rssi,
  );
}

DiscoveredDevice deviceFromDiscovery(BtcDevice device) {
  return DiscoveredDevice(
    name: displayDeviceName(device.name, device.alias),
    address: device.address,
    isPaired: device.bondState == BtcBondState.bonded,
    source: DiscoverySource.discovered,
    rssi: device.rssi,
  );
}

List<DiscoveredDevice> mergeDevices(
  List<DiscoveredDevice> current,
  Iterable<DiscoveredDevice> incoming,
) {
  final map = <String, DiscoveredDevice>{
    for (final d in current) d.address: d,
  };
  for (final next in incoming) {
    final existing = map[next.address];
    if (existing == null) {
      map[next.address] = next;
      continue;
    }
    final paired = existing.isPaired || next.isPaired;
    final source = paired ? DiscoverySource.paired : existing.source;
    final name = _betterName(existing.name, next.name);
    map[next.address] = existing.copyWith(
      name: name,
      isPaired: paired,
      source: source,
      rssi: next.rssi ?? existing.rssi,
    );
  }
  final list = map.values.toList();
  list.sort((a, b) {
    if (a.isPaired != b.isPaired) return a.isPaired ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}

String _betterName(String a, String b) {
  if (a == 'Unknown Device' && b != 'Unknown Device') return b;
  return a;
}
