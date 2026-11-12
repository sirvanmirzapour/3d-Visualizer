import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    value: Strings.tr(locale, 'persian'),
                    items: [
                      Strings.tr(locale, 'english'),
                      Strings.tr(locale, 'persian'),
                    ],
                    onChanged: (v) {
                      controller.setLocale(
                        v == Strings.tr(locale, 'persian') ? AppLocale.fa : AppLocale.en,
                      );
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

  void _showAboutDialog(BuildContext context, AppLocale locale) {
    final isFa = locale == AppLocale.fa;
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
                        isFa ? 'اسکنر میدان مغناطیسی • نسخه 1.0.0' : 'Magnetic Field Scanner • v1.0.0',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isFa ? 'تماس با من' : 'Contact',
              style: AppTextStyles.overline.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _contactTile(
              context,
              icon: Icons.telegram,
              label: 'Telegram',
              value: '@sirvanmi',
              url: 'https://t.me/sirvanmi',
              isFa: isFa,
            ),
            const SizedBox(height: 8),
            _contactTile(
              context,
              icon: Icons.language,
              label: 'Website',
              value: 'sirvanmi.ir',
              url: 'https://sirvanmi.ir',
              isFa: isFa,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isFa ? 'بستن' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String url,
    required bool isFa,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isFa ? 'باز کردن ناموفق بود' : 'Could not open link')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isFa ? 'برنامه‌ای برای باز کردن یافت نشد' : 'No app found to open this')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text(value, style: AppTextStyles.bodyStrong),
                ],
              ),
            ),
            IconButton(
              tooltip: isFa ? 'کپی' : 'Copy',
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AppColors.textSecondary,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(isFa ? 'کپی شد' : 'Copied'), duration: const Duration(seconds: 1)),
                  );
              },
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
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
