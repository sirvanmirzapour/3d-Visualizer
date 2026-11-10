import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/bluetooth/bluetooth_connection_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../bluetooth/presentation/controllers/bluetooth_connection_provider.dart';
import '../widgets/field_map_widget.dart';

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
  void _showUiOnly(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            if (widget.embedded) _embeddedIntro(context),
            if (widget.embedded) const SizedBox(height: 12),
            _header(total, conn.status, conn.deviceName),
            const SizedBox(height: 12),
            _valueCard(measurements),
            const SizedBox(height: 12),
            const SectionHeader(
              title: 'Heatmap',
              subtitle: 'Each received reading fills one cell (in order)',
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldMapWidget(
                    rows: widget.rows,
                    columns: widget.columns,
                    measurements: measurements,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pinch to zoom and drag to inspect the grid.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _infoSection(total, received, remaining, progress),
            const SizedBox(height: 12),
            _controls(context),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Scan')),
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scan'),
      ),
      body: content,
    );
  }

  Widget _embeddedIntro(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready for a new session', style: AppTextStyles.title),
                SizedBox(height: 4),
                Text(
                  'Configure dimensions to open a dedicated live scan view.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  Widget _header(int total, BluetoothServiceStatus status, String? deviceName) {
    late String label;
    late Color color;
    late IconData icon;
    switch (status) {
      case BluetoothServiceStatus.connected:
        label = 'Receiving';
        color = AppColors.success;
        icon = Icons.graphic_eq;
        break;
      case BluetoothServiceStatus.connecting:
      case BluetoothServiceStatus.disconnecting:
        label = 'Connecting';
        color = AppColors.warning;
        icon = Icons.hourglass_top;
        break;
      case BluetoothServiceStatus.error:
        label = 'Error';
        color = AppColors.error;
        icon = Icons.error_outline;
        break;
      case BluetoothServiceStatus.disconnected:
        label = 'Idle';
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
              const Expanded(
                child: Text('Live Scan', style: AppTextStyles.headline),
              ),
              StatusPill(label: label, color: color, icon: icon),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grid: ${widget.rows} × ${widget.columns} ($total points)',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 4),
          Text(
            status == BluetoothServiceStatus.connected
                ? 'Receiving data from ${deviceName ?? 'device'}'
                : 'Connect a Bluetooth device to receive scan data.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _valueCard(List<num> measurements) {
    final last = measurements.isEmpty ? null : measurements.last;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Latest Value',
            subtitle: 'Most recent reading from the device',
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
                      ? 'Waiting for data'
                      : 'Reading ${measurements.length}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(int total, int received, int remaining, double progress) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Scan Information',
            subtitle: 'Live progress',
          ),
          const SizedBox(height: 12),
          _row('Total Points', '$total'),
          _row('Received Points', '$received'),
          _row('Remaining Points', '$remaining'),
          _row('Progress Percentage', '${(progress * 100).toStringAsFixed(0)}%'),
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

  Widget _controls(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Controls',
            subtitle: 'Reset starts a fresh grid',
          ),
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
                label: const Text('Reset Data'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showUiOnly('Saving will be implemented in a later phase.'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Scan'),
              ),
              if (!widget.embedded)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
                  icon: const Icon(Icons.tune),
                  label: const Text('Change Grid'),
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
