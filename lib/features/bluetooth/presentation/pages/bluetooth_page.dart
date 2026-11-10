import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/bluetooth/bluetooth_permission_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/entities/discovered_device.dart';
import '../controllers/bluetooth_discovery_providers.dart';
import '../controllers/bluetooth_permission_providers.dart';

class BluetoothPage extends ConsumerStatefulWidget {
  const BluetoothPage({super.key});

  @override
  ConsumerState<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends ConsumerState<BluetoothPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final readiness = ref.read(bluetoothReadinessProvider).asData?.value;
      if (readiness != null && readiness.supported) {
        ref.read(bluetoothDiscoveryProvider.notifier).loadPairedDevices();
      }
    });
  }

  @override
  void dispose() {
    // Best-effort stop; provider dispose also stops.
    ref.read(bluetoothDiscoveryProvider.notifier).stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readinessAsync = ref.watch(bluetoothReadinessProvider);
    final discovery = ref.watch(bluetoothDiscoveryProvider);

    ref.listen(bluetoothReadinessProvider, (prev, next) {
      final value = next.asData?.value;
      if (value != null && value.supported && value.enabled) {
        ref.read(bluetoothDiscoveryProvider.notifier).loadPairedDevices();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: () {
              ref.invalidate(bluetoothReadinessProvider);
              final r = ref.read(bluetoothReadinessProvider).asData?.value;
              if (r?.supported == true) {
                ref.read(bluetoothDiscoveryProvider.notifier).loadPairedDevices();
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: readinessAsync.when(
            data: (state) => _buildContent(context, state, discovery),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Bluetooth status unavailable',
                message: 'Could not read Bluetooth state: $e',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BluetoothPermissionState readiness,
    BluetoothDiscoveryState discovery,
  ) {
    final service = ref.read(bluetoothPermissionServiceProvider);
    final scanning = discovery.status == DiscoveryStatus.scanning;
    final canScan = readiness.canScan;
    final scanEnabled = canScan || scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Connection Manager',
                subtitle: 'Bluetooth Classic discovery for HC-05 and compatible devices',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusPill(
                    label: _statusLabel(readiness, discovery),
                    color: _statusColor(readiness, discovery),
                    icon: _statusIcon(readiness, discovery),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: scanEnabled
                        ? () async {
                            if (scanning) {
                              await ref.read(bluetoothDiscoveryProvider.notifier).stopScan();
                            } else if (canScan) {
                              await ref.read(bluetoothDiscoveryProvider.notifier).startScan();
                            }
                          }
                        : null,
                    icon: scanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(scanning ? 'Stop Scan' : 'Scan Devices'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row('Bluetooth Status', _bluetoothStatusText(readiness)),
              _row('Permission', _permissionText(readiness.permissionStatus)),
              _row('Selected Device', 'None'),
              _row('Connection Status', 'Disconnected'),
              if (readiness.locationServiceRequired)
                _row(
                  'Location Services',
                  readiness.locationServiceEnabled ? 'On' : 'Off (required)',
                ),
              const SizedBox(height: 10),
              Text(
                discovery.message ?? readiness.message,
                style: AppTextStyles.caption.copyWith(
                  color: discovery.status == DiscoveryStatus.error
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _actions(context, ref, service, readiness),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _deviceLists(discovery, readiness),
        ),
      ],
    );
  }

  Widget _deviceLists(BluetoothDiscoveryState discovery, BluetoothPermissionState readiness) {
    final paired = discovery.pairedDevices;
    final discovered = discovery.discoveredDevices;
    final scanning = discovery.status == DiscoveryStatus.scanning;
    final noneFound = paired.isEmpty && discovered.isEmpty;

    if (noneFound) {
      return Center(
        child: EmptyState(
          icon: scanning ? Icons.bluetooth_searching : Icons.devices_other_outlined,
          title: scanning ? 'Scanning for devices...' : 'No devices found',
          message: scanning
              ? 'Looking for nearby Bluetooth Classic devices, including HC-05 modules.'
              : readiness.canScan
                  ? 'No paired or discovered devices yet. Make sure the device is powered on and in range, then scan again.'
                  : 'Resolve the Bluetooth or permission prerequisites above to scan for devices.',
        ),
      );
    }

    return ListView(
      children: [
        if (paired.isNotEmpty) ...[
          SectionHeader(
            title: 'Paired Devices',
            subtitle: '${paired.length} bonded device(s) available on this phone',
          ),
          const SizedBox(height: 8),
          ...paired.map((d) => _deviceTile(d, paired: true)),
          const SizedBox(height: 16),
        ],
        SectionHeader(
          title: 'Discovered Devices',
          subtitle: scanning
              ? 'Scanning nearby Bluetooth Classic devices...'
              : discovered.isEmpty
                  ? 'No new nearby devices found'
                  : '${discovered.length} device(s) found nearby',
        ),
        const SizedBox(height: 8),
        if (scanning && discovered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!scanning && discovered.isEmpty)
          const AppCard(
            child: Text(
              'No new discoverable devices detected. HC-05 must be powered and discoverable if not already paired.',
              style: AppTextStyles.caption,
            ),
          ),
        ...discovered.map((d) => _deviceTile(d, paired: false)),
      ],
    );
  }

  Widget _deviceTile(DiscoveredDevice device, {required bool paired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Icon(
              paired ? Icons.bluetooth_connected : Icons.bluetooth,
              color: paired ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: AppTextStyles.body),
                  const SizedBox(height: 4),
                  Text(device.address, style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(paired ? 'Paired' : 'Discovered', paired ? AppColors.success : AppColors.secondary),
                      _chip(paired ? 'Source: Paired' : 'Source: Discovered', AppColors.textSecondary),
                      if (device.rssi != null)
                        _chip('RSSI ${device.rssi} dBm', AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: null, // Connection implemented in Step 4
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    BluetoothPermissionService service,
    BluetoothPermissionState state,
  ) {
    final actions = <Widget>[];
    switch (state.readiness) {
      case BluetoothReadiness.disabled:
        actions.add(
          OutlinedButton.icon(
            onPressed: () async {
              await service.enableBluetooth();
              ref.invalidate(bluetoothReadinessProvider);
            },
            icon: const Icon(Icons.bluetooth),
            label: const Text('Turn On Bluetooth'),
          ),
        );
        break;
      case BluetoothReadiness.permissionDenied:
        actions.add(
          ElevatedButton.icon(
            onPressed: () async {
              await service.requestPermissions();
              ref.invalidate(bluetoothReadinessProvider);
            },
            icon: const Icon(Icons.security),
            label: const Text('Grant Permissions'),
          ),
        );
        break;
      case BluetoothReadiness.permissionPermanentlyDenied:
        actions.add(
          ElevatedButton.icon(
            onPressed: () async {
              await service.openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open App Settings'),
          ),
        );
        break;
      case BluetoothReadiness.locationRequired:
        actions.add(
          OutlinedButton.icon(
            onPressed: () async {
              await service.openLocationSettings();
              ref.invalidate(bluetoothReadinessProvider);
            },
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Open Location Settings'),
          ),
        );
        break;
      case BluetoothReadiness.unsupported:
      case BluetoothReadiness.ready:
        break;
    }
    return actions;
  }

  String _statusLabel(BluetoothPermissionState state, BluetoothDiscoveryState discovery) {
    if (discovery.status == DiscoveryStatus.scanning) return 'Scanning';
    if (discovery.status == DiscoveryStatus.error) return 'Error';
    switch (state.readiness) {
      case BluetoothReadiness.ready:
        return discovery.status == DiscoveryStatus.scanCompleted ? 'Scan Complete' : 'Ready';
      case BluetoothReadiness.disabled:
        return 'Bluetooth Off';
      case BluetoothReadiness.permissionDenied:
      case BluetoothReadiness.permissionPermanentlyDenied:
        return 'Permission Required';
      case BluetoothReadiness.locationRequired:
        return 'Location Required';
      case BluetoothReadiness.unsupported:
        return 'Unsupported';
    }
  }

  Color _statusColor(BluetoothPermissionState state, BluetoothDiscoveryState discovery) {
    if (discovery.status == DiscoveryStatus.scanning) return AppColors.primary;
    if (discovery.status == DiscoveryStatus.error) return AppColors.error;
    switch (state.readiness) {
      case BluetoothReadiness.ready:
        return AppColors.success;
      case BluetoothReadiness.disabled:
      case BluetoothReadiness.permissionDenied:
      case BluetoothReadiness.permissionPermanentlyDenied:
      case BluetoothReadiness.locationRequired:
        return AppColors.warning;
      case BluetoothReadiness.unsupported:
        return AppColors.error;
    }
  }

  IconData _statusIcon(BluetoothPermissionState state, BluetoothDiscoveryState discovery) {
    if (discovery.status == DiscoveryStatus.scanning) return Icons.bluetooth_searching;
    if (discovery.status == DiscoveryStatus.error) return Icons.error_outline;
    switch (state.readiness) {
      case BluetoothReadiness.ready:
        return Icons.bluetooth;
      case BluetoothReadiness.disabled:
        return Icons.bluetooth_disabled;
      case BluetoothReadiness.permissionDenied:
      case BluetoothReadiness.permissionPermanentlyDenied:
        return Icons.security;
      case BluetoothReadiness.locationRequired:
        return Icons.location_off_outlined;
      case BluetoothReadiness.unsupported:
        return Icons.bluetooth_disabled;
    }
  }

  String _bluetoothStatusText(BluetoothPermissionState state) {
    if (!state.supported) return 'Unsupported on this device';
    return state.enabled ? 'On' : 'Off';
  }

  String _permissionText(dynamic status) {
    final s = status.toString().split('.').last;
    switch (s) {
      case 'granted':
        return 'Granted';
      case 'denied':
        return 'Denied (can request)';
      case 'permanentlyDenied':
        return 'Permanently denied';
      case 'notRequired':
        return 'Not required';
      default:
        return s;
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          const SizedBox(width: 8),
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
}
