import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
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
    final locale = ref.watch(localeProvider);

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
              _buildHeader(context, readiness, locale),
              const SizedBox(height: 16),
              _buildDeviceStatusCard(context, readiness, locale),
              const SizedBox(height: 16),
              _buildStartScanCard(context, locale),
              const SizedBox(height: 16),
              _buildLastScanCard(locale),
              const SizedBox(height: 16),
              _buildStats(locale),
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
    AppLocale locale,
  ) {
    final status = readiness.asData?.value;
    final label = _headerStatus(status, locale);
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

  String _headerStatus(BluetoothPermissionState? state, AppLocale locale) {
    if (state == null) return Strings.tr(locale, 'scanning');
    if (!state.supported) return Strings.tr(locale, 'error');
    if (!state.enabled) return '${Strings.tr(locale, 'bluetoothStatus')} Off';
    if (!state.canScan) return 'Setup Needed';
    return Strings.tr(locale, 'disconnected');
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
    AppLocale locale,
  ) {
    final state = readiness.asData?.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: Strings.tr(locale, 'deviceStatus'),
            subtitle: Strings.tr(locale, 'deviceStatusSub'),
          ),
          const SizedBox(height: 14),
          _infoRow(Strings.tr(locale, 'bluetoothStatus'), _btStatus(state, readiness, locale)),
          _infoRow(Strings.tr(locale, 'deviceName'), Strings.tr(locale, 'noDeviceSelected')),
          _infoRow(Strings.tr(locale, 'connectionStatus'), Strings.tr(locale, 'disconnected')),
          _infoRow(Strings.tr(locale, 'lastMeasurement'), '—'),
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

  Widget _buildLastScanCard(AppLocale locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: Strings.tr(locale, 'lastScan'),
          subtitle: Strings.tr(locale, 'lastScanSub'),
        ),
        const SizedBox(height: 10),
        EmptyState(
          icon: Icons.history_toggle_off,
          title: Strings.tr(locale, 'noPreviousScans'),
          message: Strings.tr(locale, 'noPreviousScansMsg'),
        ),
      ],
    );
  }

  Widget _buildStats(AppLocale locale) {
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
                value: '0',
                icon: Icons.layers_outlined,
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: Strings.tr(locale, 'completed'),
                value: '0',
                icon: Icons.check_circle_outline,
                accent: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MetricTile(
          label: Strings.tr(locale, 'incompleteScans'),
          value: '0',
          icon: Icons.timelapse,
          accent: AppColors.warning,
        ),
      ],
    );
  }
}
