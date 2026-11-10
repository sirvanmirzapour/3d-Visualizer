import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/file_prefs.dart';

class ScanRecord {
  final String id;
  final DateTime createdAt;
  final int rows;
  final int columns;
  final List<num> measurements;

  const ScanRecord({
    required this.id,
    required this.createdAt,
    required this.rows,
    required this.columns,
    required this.measurements,
  });

  bool get complete => measurements.length >= rows * columns;
  int get points => measurements.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'rows': rows,
        'columns': columns,
        'measurements': measurements.map((e) => e.toDouble()).toList(),
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rows: json['rows'] as int,
        columns: json['columns'] as int,
        measurements: (json['measurements'] as List).map((e) => e as num).toList(),
      );
}

class ScanRepository {
  static const _file = 'scans.json';

  final List<ScanRecord> _memory = [];
  bool _loaded = false;

  Future<List<ScanRecord>> loadAll() async {
    if (_loaded) return List.of(_memory);
    _loaded = true;

    final raw = await FilePrefs.read(_file);
    if (raw == null) return const [];

    try {
      final list = jsonDecode(raw) as List;
      final scans = list
          .map((e) => ScanRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _memory
        ..clear()
        ..addAll(scans);
    } catch (_) {}

    return List.of(_memory);
  }

  Future<void> add(ScanRecord record) async {
    await loadAll();
    _memory.insert(0, record);
    await _persist();
  }

  Future<void> delete(String id) async {
    await loadAll();
    _memory.removeWhere((s) => s.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    await FilePrefs.write(
      _file,
      jsonEncode(_memory.map((e) => e.toJson()).toList()),
    );
  }
}

final scanRepositoryProvider = Provider<ScanRepository>((ref) => ScanRepository());

final savedScansProvider = FutureProvider<List<ScanRecord>>((ref) async {
  return ref.watch(scanRepositoryProvider).loadAll();
});
