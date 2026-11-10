import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/bluetooth/bluetooth_permission_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../bluetooth/presentation/controllers/bluetooth_permission_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(bluetoothReadinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magnetic Scanner'),
        actions: [
          IconButton(
            tooltip: 'Bluetooth',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.bluetooth),
            icon: const Icon(Icons.bluetooth),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _openSettingsTab(context),
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
              _buildHeader(context, readiness),
              const SizedBox(height: 16),
              _buildDeviceStatusCard(context, readiness),
              const SizedBox(height: 16),
              _buildStartScanCard(context),
              const SizedBox(height: 16),
              _buildLastScanCard(),
              const SizedBox(height: 16),
              _buildStats(),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettingsTab(BuildContext context) {
    final state = context.findAncestorStateOfType<State<MainNavigationShell>>();
    if (state != null) {
      // ignore: invalid_use_of_protected_member
      (state as dynamic).setState(() {
        (state as dynamic)._index = 3;
      });
    }
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<BluetoothPermissionState> readiness,
  ) {
    final status = readiness.asData?.value;
    final label = _headerStatus(status);
    final color = _headerColor(status);
    const icon = Icons.link_off;
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: AppTextStyles.title),
                SizedBox(height: 4),
                Text(
                  'Scientific magnetic field scanning workspace',
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

  String _headerStatus(BluetoothPermissionState? state) {
    if (state == null) return 'Checking...';
    if (!state.supported) return 'Unsupported';
    if (!state.enabled) return 'Bluetooth Off';
    if (!state.canScan) return 'Setup Needed';
    return 'Disconnected';
  }

  Color _headerColor(BluetoothPermissionState? state) {
    if (state == null) return AppColors.textSecondary;
    if (!state.supported) return AppColors.error;
    if (state.canScan) return AppColors.error;
    return AppColors.warning;
  }

  Widget _buildDeviceStatusCard(
    BuildContext context,
    AsyncValue<BluetoothPermissionState> readiness,
  ) {
    final state = readiness.asData?.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Device Status',
            subtitle: 'Bluetooth Classic connection overview',
          ),
          const SizedBox(height: 14),
          _infoRow('Bluetooth Status', _btStatus(state, readiness)),
          _infoRow('Device Name', 'No device selected'),
          _infoRow('Connection Status', 'Disconnected'),
          _infoRow('Last Measurement', '—'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.bluetooth),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Manage Connection'),
            ),
          ),
        ],
      ),
    );
  }

  String _btStatus(
    BluetoothPermissionState? state,
    AsyncValue<BluetoothPermissionState> readiness,
  ) {
    if (readiness.isLoading) return 'Checking...';
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

  Widget _buildStartScanCard(BuildContext context) {
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Scan', style: AppTextStyles.headline),
                        SizedBox(height: 4),
                        Text(
                          'Configure grid dimensions and prepare a new magnetic field survey.',
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
                label: const Text('Start New Scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastScanCard() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Last Scan',
          subtitle: 'Most recent saved survey session',
        ),
        SizedBox(height: 10),
        EmptyState(
          icon: Icons.history_toggle_off,
          title: 'No previous scans',
          message: 'Completed or saved scans will appear here in a future phase.',
        ),
      ],
    );
  }

  Widget _buildStats() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Overview',
          subtitle: 'Scan activity summary',
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Total Scans',
                value: '0',
                icon: Icons.layers_outlined,
                accent: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'Completed',
                value: '0',
                icon: Icons.check_circle_outline,
                accent: AppColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        MetricTile(
          label: 'Incomplete Scans',
          value: '0',
          icon: Icons.timelapse,
          accent: AppColors.warning,
        ),
      ],
    );
  }
}
