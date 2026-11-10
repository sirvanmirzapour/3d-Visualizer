import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';

class BluetoothDeviceUiModel {
  final String name;
  final String address;
  final bool selected;

  const BluetoothDeviceUiModel({
    required this.name,
    required this.address,
    this.selected = false,
  });
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  bool _scanning = false;
  final List<BluetoothDeviceUiModel> _devices = const [];

  void _simulateScan() {
    setState(() => _scanning = true);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Devices')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Connection Manager',
                      subtitle: 'Prepare Bluetooth Classic device selection (UI only)',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const StatusPill(
                          label: 'Disconnected',
                          color: AppColors.error,
                          icon: Icons.bluetooth_disabled,
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _scanning ? null : _simulateScan,
                          icon: _scanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(_scanning ? 'Scanning...' : 'Scan Devices'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _row('Bluetooth Status', 'Unavailable in Phase 1 UI'),
                    _row('Selected Device', 'None'),
                    _row('Connection Status', 'Disconnected'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Discovered Devices',
                subtitle: 'No real devices are listed in Phase 1',
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _devices.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.bluetooth_searching,
                          title: 'No devices identified',
                          message:
                              'Use Scan Devices to search. Real Bluetooth Classic discovery and connection will be added in Phase 2.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: _devices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return AppCard(
                            child: Row(
                              children: [
                                const Icon(Icons.bluetooth, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(device.name, style: AppTextStyles.body),
                                      const SizedBox(height: 4),
                                      Text(device.address, style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: null,
                                  child: const Text('Connect'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
