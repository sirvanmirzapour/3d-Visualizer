import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/bluetooth/bluetooth_connection_service.dart';
import '../../../../services/bluetooth/bluetooth_permission_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/entities/discovered_device.dart';
import '../controllers/bluetooth_connection_provider.dart';
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
    final locale = ref.watch(localeProvider);

    ref.listen(bluetoothReadinessProvider, (prev, next) {
      final value = next.asData?.value;
      if (value != null && value.supported && value.enabled) {
        ref.read(bluetoothDiscoveryProvider.notifier).loadPairedDevices();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.tr(locale, 'bluetoothDevices')),
        actions: [
          IconButton(
            tooltip: Strings.tr(locale, 'refreshStatus'),
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
            data: (state) => _buildContent(context, state, discovery, locale),
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
    AppLocale locale,
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
              SectionHeader(
                title: Strings.tr(locale, 'connectionManager'),
                subtitle: Strings.tr(locale, 'connectionManagerSub'),
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
                    label: Text(
                      scanning ? Strings.tr(locale, 'stopScan') : Strings.tr(locale, 'scanDevices'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(Strings.tr(locale, 'bluetoothStatus'), _bluetoothStatusText(readiness)),
              _row(Strings.tr(locale, 'permission'), _permissionText(readiness.permissionStatus)),
              if (readiness.locationServiceRequired)
                _row(
                  Strings.tr(locale, 'locationServices'),
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
        const _ConnectionStatusCard(),
        const SizedBox(height: 16),
        const _DebugMonitor(),
        const SizedBox(height: 16),
        Expanded(
          child: _deviceLists(discovery, readiness, locale),
        ),
      ],
    );
  }

  Widget _deviceLists(
    BluetoothDiscoveryState discovery,
    BluetoothPermissionState readiness,
    AppLocale locale,
  ) {
    final paired = discovery.pairedDevices;
    final discovered = discovery.discoveredDevices;
    final scanning = discovery.status == DiscoveryStatus.scanning;
    final noneFound = paired.isEmpty && discovered.isEmpty;

    if (noneFound) {
      return Center(
        child: EmptyState(
          icon: scanning ? Icons.bluetooth_searching : Icons.devices_other_outlined,
          title: scanning ? Strings.tr(locale, 'scanning') : 'No devices found',
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
            title: Strings.tr(locale, 'pairedDevices'),
            subtitle: '${paired.length} bonded device(s) available on this phone',
          ),
          const SizedBox(height: 8),
          ...paired.map((d) => _DeviceTile(device: d, paired: true)),
          const SizedBox(height: 16),
        ],
        if (discovered.isNotEmpty) ...[
          SectionHeader(
            title: Strings.tr(locale, 'discoveredDevices'),
            subtitle: scanning
                ? 'Scanning nearby Bluetooth Classic devices...'
                : '${discovered.length} device(s) found nearby',
          ),
          const SizedBox(height: 8),
          ...discovered.map((d) => _DeviceTile(device: d, paired: false)),
          const SizedBox(height: 16),
        ],
        if (discovered.isEmpty && !scanning)
          const AppCard(
            child: Text(
              'No new discoverable devices detected. HC-05 must be powered and discoverable if not already paired.',
              style: AppTextStyles.caption,
            ),
          ),
      ],
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

class _DeviceTile extends ConsumerWidget {
  final DiscoveredDevice device;
  final bool paired;

  const _DeviceTile({required this.device, required this.paired});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(bluetoothConnectionProvider);
    final controller = ref.read(bluetoothConnectionProvider.notifier);
    final locale = ref.watch(localeProvider);

    final busy = conn.status == BluetoothServiceStatus.connecting ||
        conn.status == BluetoothServiceStatus.disconnecting;
    final isThisConnected =
        conn.status == BluetoothServiceStatus.connected && conn.deviceAddress == device.address;
    final otherConnected =
        conn.status == BluetoothServiceStatus.connected && !isThisConnected;

    Widget connectButton;
    if (isThisConnected) {
      connectButton = ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        child: Text(Strings.tr(locale, 'connected')),
      );
    } else if (busy) {
      connectButton = OutlinedButton(
        onPressed: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(Strings.tr(locale, 'connectingEllipsis')),
          ],
        ),
      );
    } else {
      connectButton = OutlinedButton(
        onPressed: otherConnected
            ? null
            : () => controller.connect(address: device.address, deviceName: device.name),
        child: Text(Strings.tr(locale, 'connect')),
      );
    }

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
                      _chip(
                        paired ? Strings.tr(locale, 'paired') : Strings.tr(locale, 'discovered'),
                        paired ? AppColors.success : AppColors.secondary,
                      ),
                      _chip(paired ? 'Source: Paired' : 'Source: Discovered', AppColors.textSecondary),
                      if (device.rssi != null)
                        _chip('RSSI ${device.rssi} dBm', AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            connectButton,
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
}

class _ConnectionStatusCard extends ConsumerWidget {
  const _ConnectionStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(bluetoothConnectionProvider);
    final controller = ref.read(bluetoothConnectionProvider.notifier);
    final locale = ref.watch(localeProvider);
    final v = _connVisual(conn.status);
    final label = _connLabel(conn.status, locale);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionHeader(title: Strings.tr(locale, 'connectionStatus'))),
              StatusPill(label: label, color: v.color, icon: v.icon),
            ],
          ),
          const SizedBox(height: 12),
          ..._statusBody(conn, controller, locale),
        ],
      ),
    );
  }

  List<Widget> _statusBody(
    BluetoothConnectionState conn,
    BluetoothConnectionController controller,
    AppLocale locale,
  ) {
    switch (conn.status) {
      case BluetoothServiceStatus.disconnected:
        return [
          _infoRow(Strings.tr(locale, 'selectedDevice'), conn.deviceName ?? Strings.tr(locale, 'none')),
          const SizedBox(height: 8),
          Text(
            Strings.tr(locale, 'selectDeviceHint'),
            style: AppTextStyles.caption,
          ),
        ];
      case BluetoothServiceStatus.connecting:
        return [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(Strings.tr(locale, 'connectingTo'), style: AppTextStyles.body)),
            ],
          ),
          if (conn.deviceName != null) ...[
            const SizedBox(height: 8),
            _infoRow(Strings.tr(locale, 'deviceName'), conn.deviceName!),
          ],
        ];
      case BluetoothServiceStatus.connected:
        return [
          _infoRow(Strings.tr(locale, 'deviceName'), conn.deviceName ?? '—'),
          _infoRow(Strings.tr(locale, 'macAddress'), conn.deviceAddress ?? '—'),
          if (conn.connectedAt != null)
            _infoRow(Strings.tr(locale, 'connectedAt'), _formatTime(conn.connectedAt!)),
          if (conn.lastDataReceivedAt != null)
            _infoRow(Strings.tr(locale, 'lastDataAt'), _formatTime(conn.lastDataReceivedAt!)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => controller.disconnect(),
              icon: const Icon(Icons.link_off),
              label: Text(Strings.tr(locale, 'disconnect')),
            ),
          ),
        ];
      case BluetoothServiceStatus.disconnecting:
        return [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(Strings.tr(locale, 'disconnectingMsg'), style: AppTextStyles.body),
            ],
          ),
        ];
      case BluetoothServiceStatus.error:
        return [
          if (conn.deviceName != null) _infoRow(Strings.tr(locale, 'deviceName'), conn.deviceName!),
          const SizedBox(height: 6),
          Text(
            conn.errorMessage ?? 'Connection failed.',
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            Strings.tr(locale, 'retryHint'),
            style: AppTextStyles.caption,
          ),
        ];
    }
  }
}

class _DebugMonitor extends ConsumerWidget {
  const _DebugMonitor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(bluetoothConnectionProvider);
    if (conn.status != BluetoothServiceStatus.connected) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(bluetoothConnectionProvider.notifier);
    final locale = ref.watch(localeProvider);
    final events = conn.recentEvents.reversed.toList();

    Widget empty = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(Strings.tr(locale, 'noDataYet'), style: AppTextStyles.caption),
    );

    Widget list = Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3442)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: events.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: const Color(0xFF2A3442)),
        itemBuilder: (context, index) {
          final ev = events[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_formatTime(ev.receivedAt), style: AppTextStyles.caption),
                    const Spacer(),
                    Text('${ev.byteCount} B', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText(
                  ev.hex,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SelectableText(
                  _bytesAsText(ev.data),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: Strings.tr(locale, 'debugMonitor'),
                  subtitle: Strings.tr(locale, 'debugMonitorSub'),
                ),
              ),
              IconButton(
                tooltip: Strings.tr(locale, 'clearDebug'),
                onPressed: () => controller.clearDebug(),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoRow(Strings.tr(locale, 'receivedEvents'), '${conn.dataEventCount}'),
          _infoRow(Strings.tr(locale, 'totalBytes'), '${conn.totalBytesReceived}'),
          _infoRow(
            Strings.tr(locale, 'lastReceived'),
            conn.lastDataReceivedAt != null ? _formatTime(conn.lastDataReceivedAt!) : '—',
          ),
          if (conn.lastRawData != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Raw Data — Hex', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  SelectableText(
                    _hexOf(conn.lastRawData!),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Text', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  SelectableText(
                    _bytesAsText(conn.lastRawData!),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(Strings.tr(locale, 'recentEvents'), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(Strings.tr(locale, 'newestFirst'), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          events.isEmpty ? empty : list,
        ],
      ),
    );
  }
}

String _connLabel(BluetoothServiceStatus s, AppLocale locale) {
  switch (s) {
    case BluetoothServiceStatus.disconnected:
      return Strings.tr(locale, 'disconnected');
    case BluetoothServiceStatus.connecting:
      return Strings.tr(locale, 'connecting');
    case BluetoothServiceStatus.connected:
      return Strings.tr(locale, 'connected');
    case BluetoothServiceStatus.disconnecting:
      return Strings.tr(locale, 'disconnecting');
    case BluetoothServiceStatus.error:
      return Strings.tr(locale, 'error');
  }
}

({String label, Color color, IconData icon}) _connVisual(BluetoothServiceStatus s) {
  switch (s) {
    case BluetoothServiceStatus.disconnected:
      return (label: 'Disconnected', color: AppColors.textSecondary, icon: Icons.link_off);
    case BluetoothServiceStatus.connecting:
      return (label: 'Connecting', color: AppColors.warning, icon: Icons.link);
    case BluetoothServiceStatus.connected:
      return (label: 'Connected', color: AppColors.success, icon: Icons.bluetooth_connected);
    case BluetoothServiceStatus.disconnecting:
      return (label: 'Disconnecting', color: AppColors.warning, icon: Icons.hourglass_top);
    case BluetoothServiceStatus.error:
      return (label: 'Error', color: AppColors.error, icon: Icons.error_outline);
  }
}

Widget _infoRow(String label, String value) {
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

String _formatTime(DateTime t) {
  final l = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

String _hexOf(List<int> data) {
  final sb = StringBuffer();
  for (final b in data) {
    if (sb.isNotEmpty) sb.write(' ');
    sb.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
  }
  return sb.toString();
}

String _bytesAsText(List<int> data) {
  final sb = StringBuffer();
  for (final b in data) {
    if (b >= 0x20 && b <= 0x7E) {
      sb.writeCharCode(b);
    } else {
      sb.write('•');
    }
  }
  return sb.toString();
}
