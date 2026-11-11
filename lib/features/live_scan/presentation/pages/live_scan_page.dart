import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/bluetooth/bluetooth_connection_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../bluetooth/presentation/controllers/bluetooth_connection_provider.dart';
import '../../../scan_history/data/scan_repository.dart';
import '../widgets/field3d_widget.dart';
import '../widgets/field_map_widget.dart';
import '../widgets/heatmap_widget.dart';

enum HeatmapMode { smooth, square }

class LiveScanPage extends ConsumerStatefulWidget {
  final int rows;
  final int columns;
  final bool embedded;

  const LiveScanPage({
    super.key,
    required this.rows,
    required this.columns,
  }) : embedded = false;

  const LiveScanPage.embedded({super.key})
      : rows = AppConstants.defaultRows,
        columns = AppConstants.defaultColumns,
        embedded = true;

  @override
  ConsumerState<LiveScanPage> createState() => _LiveScanPageState();
}

class _LiveScanPageState extends ConsumerState<LiveScanPage> {
  HeatmapMode _mode = HeatmapMode.smooth;
  bool _showValues = true;

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final conn = ref.read(bluetoothConnectionProvider);
    final measurements = conn.measurements.take(widget.rows * widget.columns).toList();
    if (measurements.isEmpty) {
      _showMsg(Strings.tr(ref.read(localeProvider), 'nothingToSave'));
      return;
    }
    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      rows: widget.rows,
      columns: widget.columns,
      measurements: measurements,
    );
    await ref.read(scanRepositoryProvider).add(record);
    ref.invalidate(savedScansProvider);
    _showMsg(Strings.tr(ref.read(localeProvider), 'scanSaved'));
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final total = widget.rows * widget.columns;
    final conn = ref.watch(bluetoothConnectionProvider);
    final measurements = conn.measurements;
    final received = measurements.length > total ? total : measurements.length;
    final remaining = total - received;
    final progress = total == 0 ? 0.0 : received / total;

    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) _embeddedIntro(context, locale),
            if (widget.embedded) const SizedBox(height: 12),
            _header(total, conn.status, conn.deviceName, locale),
            const SizedBox(height: 12),
            _valueCard(measurements, locale),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: Strings.tr(locale, 'heatmap'),
                    subtitle: Strings.tr(locale, 'heatmapSub'),
                  ),
                ),
                SegmentedButton<HeatmapMode>(
                  segments: [
                    ButtonSegment(
                      value: HeatmapMode.smooth,
                      label: Text(Strings.tr(locale, 'modeSmooth')),
                    ),
                    ButtonSegment(
                      value: HeatmapMode.square,
                      label: Text(Strings.tr(locale, 'modeSquare')),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.numbers, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Show values', style: AppTextStyles.body)),
                Switch(
                  value: _showValues,
                  onChanged: (v) => setState(() => _showValues = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _openFullscreen,
                        behavior: HitTestBehavior.opaque,
                        child: _buildMap(measurements),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: IconButton.filledTonal(
                          tooltip: 'Fullscreen',
                          onPressed: _openFullscreen,
                          icon: const Icon(Icons.fullscreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pinch to zoom and drag to inspect the grid.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _infoSection(total, received, remaining, progress, locale),
            const SizedBox(height: 12),
            _controls(context, locale),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: Text(Strings.tr(locale, 'liveScan'))),
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(Strings.tr(locale, 'liveScan'))),
      body: content,
    );
  }

  Widget _buildMap(List<num> measurements) {
    if (_mode == HeatmapMode.smooth) {
      return FieldMapWidget(
        rows: widget.rows,
        columns: widget.columns,
        measurements: measurements,
        showValues: _showValues,
      );
    }
    return AspectRatio(
      aspectRatio: widget.columns / widget.rows,
      child: HeatmapWidget(
        rows: widget.rows,
        columns: widget.columns,
        values: measurements,
        showValues: _showValues,
      ),
    );
  }

  void _openFullscreen() {
    final measurements = ref.read(bluetoothConnectionProvider).measurements;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenMap(
          rows: widget.rows,
          columns: widget.columns,
          measurements: measurements,
          mode: _mode,
          showValues: _showValues,
        ),
      ),
    );
  }

  Widget _embeddedIntro(BuildContext context, AppLocale locale) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.tr(locale, 'readyNewSession'), style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  Strings.tr(locale, 'readyNewSessionSub'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
            child: Text(Strings.tr(locale, 'configure')),
          ),
        ],
      ),
    );
  }

  Widget _header(int total, BluetoothServiceStatus status, String? deviceName, AppLocale locale) {
    late String label;
    late Color color;
    late IconData icon;
    switch (status) {
      case BluetoothServiceStatus.connected:
        label = Strings.tr(locale, 'receiving');
        color = AppColors.success;
        icon = Icons.graphic_eq;
        break;
      case BluetoothServiceStatus.connecting:
      case BluetoothServiceStatus.disconnecting:
        label = Strings.tr(locale, 'connecting');
        color = AppColors.warning;
        icon = Icons.hourglass_top;
        break;
      case BluetoothServiceStatus.error:
        label = Strings.tr(locale, 'error');
        color = AppColors.error;
        icon = Icons.error_outline;
        break;
      case BluetoothServiceStatus.disconnected:
        label = Strings.tr(locale, 'idle');
        color = AppColors.secondary;
        icon = Icons.pause_circle_outline;
        break;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(Strings.tr(locale, 'liveScan'), style: AppTextStyles.headline)),
              StatusPill(label: label, color: color, icon: icon),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Strings.tr(locale, 'gridNotation', {'rows': '$widget.rows', 'columns': '$widget.columns', 'points': '$total'}),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 4),
          Text(
            status == BluetoothServiceStatus.connected
                ? '${Strings.tr(locale, 'receivingFrom')} ${deviceName ?? 'device'}'
                : Strings.tr(locale, 'connectDeviceHint'),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _valueCard(List<num> measurements, AppLocale locale) {
    final last = measurements.isEmpty ? null : measurements.last;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: Strings.tr(locale, 'latestValue'),
            subtitle: Strings.tr(locale, 'latestValueSub'),
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  last == null ? '—' : last.toString(),
                  style: AppTextStyles.valueLarge.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  last == null
                      ? Strings.tr(locale, 'waitingForData')
                      : '${Strings.tr(locale, 'reading')} ${measurements.length}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(int total, int received, int remaining, double progress, AppLocale locale) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: Strings.tr(locale, 'scanInfo'),
            subtitle: Strings.tr(locale, 'scanInfoSub'),
          ),
          const SizedBox(height: 12),
          _row(Strings.tr(locale, 'totalPoints'), '$total'),
          _row(Strings.tr(locale, 'receivedPoints'), '$received'),
          _row(Strings.tr(locale, 'remainingPoints'), '$remaining'),
          _row(Strings.tr(locale, 'progressPercentage'), '${(progress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context, AppLocale locale) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: Strings.tr(locale, 'controls')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(bluetoothConnectionProvider.notifier).clearMeasurements();
                },
                icon: const Icon(Icons.refresh),
                label: Text(Strings.tr(locale, 'resetData')),
              ),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(Strings.tr(locale, 'saveScan')),
              ),
              if (!widget.embedded)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
                  icon: const Icon(Icons.tune),
                  label: Text(Strings.tr(locale, 'changeGrid')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

enum _FSView { twoD, threeD }

class _FullscreenMap extends StatefulWidget {
  final int rows;
  final int columns;
  final List<num> measurements;
  final HeatmapMode mode;
  final bool showValues;

  const _FullscreenMap({
    required this.rows,
    required this.columns,
    required this.measurements,
    required this.mode,
    required this.showValues,
  });

  @override
  State<_FullscreenMap> createState() => _FullscreenMapState();
}

class _FullscreenMapState extends State<_FullscreenMap> {
  _FSView _view = _FSView.twoD;

  Widget _buildContent() {
    if (_view == _FSView.threeD) {
      return Field3DWidget(
        rows: widget.rows,
        columns: widget.columns,
        measurements: widget.measurements,
      );
    }
    if (widget.mode == HeatmapMode.smooth) {
      return FieldMapWidget(
        rows: widget.rows,
        columns: widget.columns,
        measurements: widget.measurements,
        showValues: widget.showValues,
      );
    }
    return AspectRatio(
      aspectRatio: widget.columns / widget.rows,
      child: HeatmapWidget(
        rows: widget.rows,
        columns: widget.columns,
        values: widget.measurements,
        showValues: widget.showValues,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<_FSView>(
                segments: const [
                  ButtonSegment(value: _FSView.twoD, label: Text('2D')),
                  ButtonSegment(value: _FSView.threeD, label: Text('3D')),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 12),
              if (_view == _FSView.threeD)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Drag to rotate • Pinch to zoom',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: Center(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
