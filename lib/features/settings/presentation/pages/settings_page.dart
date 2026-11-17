import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _heatmapMode = 'cell';
  int _defaultRows = AppConstants.defaultRows;
  int _defaultCols = AppConstants.defaultColumns;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final locale = settings.locale;

    return Scaffold(
      appBar: AppBar(title: Text(Strings.tr(locale, 'settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(
              title: Strings.tr(locale, 'general'),
              subtitle: Strings.tr(locale, 'appearance'),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _dropdownTile(
                    icon: Icons.dark_mode_outlined,
                    label: Strings.tr(locale, 'theme'),
                    value: settings.themeMode == AppThemeMode.light
                        ? Strings.tr(locale, 'light')
                        : Strings.tr(locale, 'dark'),
                    items: [
                      Strings.tr(locale, 'dark'),
                      Strings.tr(locale, 'light'),
                    ],
                    onChanged: (v) {
                      controller.setThemeMode(
                        v == Strings.tr(locale, 'light') ? AppThemeMode.light : AppThemeMode.dark,
                      );
                    },
                  ),
                  const Divider(height: 20),
                  _dropdownTile(
                    icon: Icons.language,
                    label: Strings.tr(locale, 'language'),
                    value: _localeLabel(locale, settings.locale),
                    items: [
                      _localeLabel(locale, AppLocale.en),
                      _localeLabel(locale, AppLocale.fa),
                      _localeLabel(locale, AppLocale.ku),
                      _localeLabel(locale, AppLocale.ar),
                      _localeLabel(locale, AppLocale.de),
                    ],
                    onChanged: (v) {
                      final selected = _localeItems(locale).firstWhere(
                        (e) => e.$2 == v,
                        orElse: () => (AppLocale.en, ''),
                      );
                      controller.setLocale(selected.$1);
                    },
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: Text(Strings.tr(locale, 'about'), style: AppTextStyles.body),
                    subtitle: Text(Strings.tr(locale, 'aboutSub'), style: AppTextStyles.caption),
                    onTap: () => _showAboutDialog(context, locale),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: Strings.tr(locale, 'bluetoothPrefs'),
              subtitle: Strings.tr(locale, 'bluetoothPrefsSub'),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bluetooth_connected, color: AppColors.primary),
                    title: Text(Strings.tr(locale, 'lastConnectedDevice'), style: AppTextStyles.body),
                    subtitle: Text(
                      settings.lastDeviceName ?? Strings.tr(locale, 'none'),
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.sync, color: AppColors.primary),
                    title: Text(Strings.tr(locale, 'autoConnect'), style: AppTextStyles.body),
                    subtitle: Text(Strings.tr(locale, 'autoConnectSub'), style: AppTextStyles.caption),
                    value: settings.autoConnect,
                    onChanged: (v) => controller.setAutoConnect(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: Strings.tr(locale, 'scanSettings'),
              subtitle: Strings.tr(locale, 'scanSettingsSub'),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _numberPickerTile(
                    icon: Icons.table_rows_outlined,
                    label: Strings.tr(locale, 'defaultRows'),
                    value: _defaultRows,
                    onChanged: (v) => setState(() => _defaultRows = v),
                  ),
                  const Divider(height: 20),
                  _numberPickerTile(
                    icon: Icons.view_column_outlined,
                    label: Strings.tr(locale, 'defaultColumns'),
                    value: _defaultCols,
                    onChanged: (v) => setState(() => _defaultCols = v),
                  ),
                  const Divider(height: 20),
                  _dropdownTile(
                    icon: Icons.gradient,
                    label: Strings.tr(locale, 'heatmapDisplayMode'),
                    value: _heatmapMode == 'cell'
                        ? Strings.tr(locale, 'cellHeatmap')
                        : Strings.tr(locale, 'smoothHeatmap'),
                    items: [
                      Strings.tr(locale, 'cellHeatmap'),
                      Strings.tr(locale, 'smoothHeatmap'),
                    ],
                    onChanged: (v) => setState(() {
                      _heatmapMode = v == Strings.tr(locale, 'cellHeatmap') ? 'cell' : 'smooth';
                    }),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Strings.tr(locale, 'settingsUiOnly'),
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

  static const _localeKeys = <AppLocale, String>{
    AppLocale.en: 'english',
    AppLocale.fa: 'persian',
    AppLocale.ku: 'kurdish',
    AppLocale.ar: 'arabic',
    AppLocale.de: 'german',
  };

  String _localeLabel(AppLocale uiLocale, AppLocale l) =>
      Strings.tr(uiLocale, _localeKeys[l]!);

  List<(AppLocale, String)> _localeItems(AppLocale uiLocale) => _localeKeys.entries
      .map((e) => (e.key, Strings.tr(uiLocale, e.value)))
      .toList();

  void _showAboutDialog(BuildContext context, AppLocale locale) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.tr(locale, 'appName'),
                        style: AppTextStyles.title.copyWith(fontSize: 18),
                      ),
                      Text(
                        Strings.tr(locale, 'aboutSub'),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              Strings.tr(locale, 'aboutMadeIn'),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            Text(
              Strings.tr(locale, 'aboutContact'),
              style: AppTextStyles.overline.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(Strings.tr(locale, 'aboutLocation'), style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(Strings.tr(locale, 'aboutPhone'), style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(Strings.tr(locale, 'aboutCountry'), style: AppTextStyles.caption),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Strings.tr(locale, 'none') == 'None' ? 'Close' : 'بستن'),
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
