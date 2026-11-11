import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/navigation/nav_controller.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/bluetooth/bluetooth_connection_service.dart';
import '../../../../services/bluetooth/bluetooth_permission_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../bluetooth/presentation/controllers/bluetooth_connection_provider.dart';
import '../../../bluetooth/presentation/controllers/bluetooth_permission_providers.dart';
import '../../../scan_history/data/scan_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(bluetoothReadinessProvider);
    final conn = ref.watch(bluetoothConnectionProvider);
    final locale = ref.watch(localeProvider);
    final scansAsync = ref.watch(savedScansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.tr(locale, 'appName')),
        actions: [
          IconButton(
            tooltip: Strings.tr(locale, 'bluetooth'),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.bluetooth),
            icon: const Icon(Icons.bluetooth),
          ),
          IconButton(
            tooltip: Strings.tr(locale, 'settings'),
            onPressed: () => _openSettingsTab(context, ref),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, readiness, conn, locale),
              const SizedBox(height: 16),
              _buildDeviceStatusCard(context, readiness, conn, locale),
              const SizedBox(height: 16),
              _buildStartScanCard(context, locale),
              const SizedBox(height: 16),
              _buildLastScanCard(context, locale, scansAsync),
              const SizedBox(height: 16),
              _buildStats(locale, scansAsync),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettingsTab(BuildContext context, WidgetRef ref) {
    ref.read(navControllerProvider.notifier).goTo(3);
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<BluetoothPermissionState> readiness,
    BluetoothConnectionState conn,
    AppLocale locale,
  ) {
    final status = readiness.asData?.value;
    final label = _headerStatus(status, conn, locale);
    final color = _headerColor(status, conn);
    final icon = conn.status == BluetoothServiceStatus.connected
        ? Icons.bluetooth_connected
        : Icons.link_off;
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.radar, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.tr(locale, 'dashboard'), style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  Strings.tr(locale, 'subtitle'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          StatusPill(label: label, color: color, icon: icon),
        ],
      ),
    );
  }

  String _headerStatus(
    BluetoothPermissionState? state,
    BluetoothConnectionState conn,
    AppLocale locale,
  ) {
    if (conn.status == BluetoothServiceStatus.connected) return Strings.tr(locale, 'connected');
    if (conn.status == BluetoothServiceStatus.error) return Strings.tr(locale, 'error');
    if (state == null) return Strings.tr(locale, 'scanning');
    if (!state.supported) return Strings.tr(locale, 'error');
    if (!state.enabled) return '${Strings.tr(locale, 'bluetoothStatus')} Off';
    if (!state.canScan) return 'Setup Needed';
    return Strings.tr(locale, 'disconnected');
  }

  Color _headerColor(BluetoothPermissionState? state, BluetoothConnectionState conn) {
    if (conn.status == BluetoothServiceStatus.connected) return AppColors.success;
    if (conn.status == BluetoothServiceStatus.error) return AppColors.error;
    if (state == null) return AppColors.textSecondary;
    if (!state.supported) return AppColors.error;
    if (state.canScan) return AppColors.error;
    return AppColors.warning;
  }

  Widget _buildDeviceStatusCard(
    BuildContext context,
    AsyncValue<BluetoothPermissionState> readiness,
    BluetoothConnectionState conn,
    AppLocale locale,
  ) {
    final state = readiness.asData?.value;
    final deviceName = conn.status == BluetoothServiceStatus.connected ||
            conn.deviceName != null
        ? (conn.deviceName ?? '—')
        : Strings.tr(locale, 'noDeviceSelected');
    final connLabel = _connLabel(conn.status, locale);
    final connColor = _connColor(conn.status);
    final lastVal = conn.measurements.isEmpty ? '—' : conn.measurements.last.toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: Strings.tr(locale, 'deviceStatus'),
            subtitle: Strings.tr(locale, 'deviceStatusSub'),
            trailing: StatusPill(label: connLabel, color: connColor),
          ),
          const SizedBox(height: 14),
          _infoRow(Strings.tr(locale, 'bluetoothStatus'), _btStatus(state, readiness, locale)),
          _infoRow(Strings.tr(locale, 'deviceName'), deviceName),
          if (conn.status == BluetoothServiceStatus.connected)
            _infoRow(Strings.tr(locale, 'macAddress'), conn.deviceAddress ?? '—'),
          _infoRow(Strings.tr(locale, 'connectionStatus'), connLabel),
          _infoRow(Strings.tr(locale, 'lastMeasurement'), lastVal),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.bluetooth),
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(Strings.tr(locale, 'manageConnection')),
            ),
          ),
        ],
      ),
    );
  }

  String _connLabel(BluetoothServiceStatus s, AppLocale locale) {
    switch (s) {
      case BluetoothServiceStatus.connected:
        return Strings.tr(locale, 'connected');
      case BluetoothServiceStatus.connecting:
        return Strings.tr(locale, 'connecting');
      case BluetoothServiceStatus.disconnecting:
        return Strings.tr(locale, 'disconnecting');
      case BluetoothServiceStatus.error:
        return Strings.tr(locale, 'error');
      case BluetoothServiceStatus.disconnected:
        return Strings.tr(locale, 'disconnected');
    }
  }

  Color _connColor(BluetoothServiceStatus s) {
    switch (s) {
      case BluetoothServiceStatus.connected:
        return AppColors.success;
      case BluetoothServiceStatus.connecting:
      case BluetoothServiceStatus.disconnecting:
        return AppColors.warning;
      case BluetoothServiceStatus.error:
        return AppColors.error;
      case BluetoothServiceStatus.disconnected:
        return AppColors.textSecondary;
    }
  }

  String _btStatus(
    BluetoothPermissionState? state,
    AsyncValue<BluetoothPermissionState> readiness,
    AppLocale locale,
  ) {
    if (readiness.isLoading) return Strings.tr(locale, 'scanning');
    if (readiness.hasError) return 'Unavailable';
    if (state == null) return 'Unavailable';
    if (!state.supported) return 'Unsupported';
    if (!state.enabled) return 'Off';
    if (state.canScan) return 'On (ready)';
    return 'On (setup needed)';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScanCard(BuildContext context, AppLocale locale) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.22),
              AppColors.secondary.withValues(alpha: 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.grid_on, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Strings.tr(locale, 'newScan'), style: AppTextStyles.headline),
                        const SizedBox(height: 4),
                        Text(
                          Strings.tr(locale, 'newScanSub'),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(Strings.tr(locale, 'startNewScan')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastScanCard(
    BuildContext context,
    AppLocale locale,
    AsyncValue<List<ScanRecord>> scansAsync,
  ) {
    final scans = scansAsync.valueOrNull;
    final last = (scans == null || scans.isEmpty) ? null : scans.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: Strings.tr(locale, 'lastScan'),
          subtitle: Strings.tr(locale, 'lastScanSub'),
        ),
        const SizedBox(height: 10),
        if (last == null)
          EmptyState(
            icon: Icons.history_toggle_off,
            title: Strings.tr(locale, 'noPreviousScans'),
            message: Strings.tr(locale, 'noPreviousScansMsg'),
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.scanDetail,
              arguments: {
                'title': 'Scan ${scans!.length}',
                'date': last.createdAt,
                'rows': last.rows,
                'columns': last.columns,
                'points': last.points,
                'status': last.complete ? 'Complete' : 'Incomplete',
                'measurements': last.measurements,
              },
            ),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${last.rows}×${last.columns} • ${last.points} ${Strings.tr(locale, 'points')}', style: AppTextStyles.title.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_fmtDate(last.createdAt), style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(AppLocale locale, AsyncValue<List<ScanRecord>> scansAsync) {
    final scans = scansAsync.valueOrNull ?? const <ScanRecord>[];
    final total = scans.length;
    final completed = scans.where((s) => s.complete).length;
    final incomplete = total - completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: Strings.tr(locale, 'overview'),
          subtitle: Strings.tr(locale, 'overviewSub'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: Strings.tr(locale, 'totalScans'),
                value: '$total',
                icon: Icons.layers_outlined,
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: Strings.tr(locale, 'completed'),
                value: '$completed',
                icon: Icons.check_circle_outline,
                accent: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MetricTile(
          label: Strings.tr(locale, 'incompleteScans'),
          value: '$incomplete',
          icon: Icons.timelapse,
          accent: AppColors.warning,
        ),
      ],
    );
  }

  String _fmtDate(DateTime t) {
    final l = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.year)}/${two(l.month)}/${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
