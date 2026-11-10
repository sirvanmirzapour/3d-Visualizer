import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoConnect = false;
  String _theme = 'Dark';
  String _language = 'English';
  String _heatmapMode = 'Cell Heatmap';
  int _defaultRows = AppConstants.defaultRows;
  int _defaultCols = AppConstants.defaultColumns;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'General', subtitle: 'Appearance and app information'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _dropdownTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Theme',
                    value: _theme,
                    items: const ['Dark'],
                    onChanged: (v) => setState(() => _theme = v ?? _theme),
                  ),
                  const Divider(height: 20),
                  _dropdownTile(
                    icon: Icons.language,
                    label: 'Language',
                    value: _language,
                    items: const ['English'],
                    onChanged: (v) => setState(() => _language = v ?? _language),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: const Text('About Application', style: AppTextStyles.body),
                    subtitle: const Text('Magnetic Field Scanner • Phase 1 UI', style: AppTextStyles.caption),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Magnetic Scanner',
                      applicationVersion: '1.0.0 (Phase 1)',
                      applicationLegalese: 'UI foundation for magnetic field scanning.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Bluetooth', subtitle: 'Connection preferences (UI only)'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.bluetooth_connected, color: AppColors.primary),
                    title: Text('Last Connected Device', style: AppTextStyles.body),
                    subtitle: Text('None', style: AppTextStyles.caption),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.sync, color: AppColors.primary),
                    title: const Text('Auto Connect', style: AppTextStyles.body),
                    subtitle: const Text('Attempt reconnect on app start (future)', style: AppTextStyles.caption),
                    value: _autoConnect,
                    onChanged: (v) => setState(() => _autoConnect = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Scan Settings', subtitle: 'Defaults and visualization preferences'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _numberPickerTile(
                    icon: Icons.table_rows_outlined,
                    label: 'Default Rows',
                    value: _defaultRows,
                    onChanged: (v) => setState(() => _defaultRows = v),
                  ),
                  const Divider(height: 20),
                  _numberPickerTile(
                    icon: Icons.view_column_outlined,
                    label: 'Default Columns',
                    value: _defaultCols,
                    onChanged: (v) => setState(() => _defaultCols = v),
                  ),
                  const Divider(height: 20),
                  _dropdownTile(
                    icon: Icons.gradient,
                    label: 'Heatmap Display Mode',
                    value: _heatmapMode,
                    items: const ['Cell Heatmap', 'Smooth Heatmap'],
                    onChanged: (v) => setState(() => _heatmapMode = v ?? _heatmapMode),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings are UI-only in Phase 1 and are not persisted.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox.shrink(),
          dropdownColor: AppColors.surface,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _numberPickerTile({
    required IconData icon,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        IconButton(
          onPressed: value > AppConstants.minGridSize ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: value < AppConstants.maxGridSize ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
