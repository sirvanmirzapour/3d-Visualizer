import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../live_scan/presentation/widgets/field_map_widget.dart';

class ScanDetailPage extends ConsumerWidget {
  final String title;
  final DateTime date;
  final int rows;
  final int columns;
  final int points;
  final String status;
  final List<num>? measurements;

  const ScanDetailPage({
    super.key,
    required this.title,
    required this.date,
    required this.rows,
    required this.columns,
    required this.points,
    required this.status,
    this.measurements,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final complete = status == 'Complete';
    final hasData = measurements != null && measurements!.isNotEmpty && rows > 0 && columns > 0;

    return Scaffold(
      appBar: AppBar(title: Text(Strings.tr(locale, 'scanDetails'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title, style: AppTextStyles.headline)),
                        StatusPill(
                          label: complete
                              ? Strings.tr(locale, 'complete')
                              : Strings.tr(locale, 'incomplete'),
                          color: complete ? AppColors.success : AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${Strings.tr(locale, 'date')}: ${_fmtDate(date)}', style: AppTextStyles.caption),
                    Text('${Strings.tr(locale, 'grid')}: $rows × $columns', style: AppTextStyles.caption),
                    Text('${Strings.tr(locale, 'points')}: $points', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: Strings.tr(locale, 'savedHeatmap'),
                subtitle: Strings.tr(locale, 'savedHeatmapSub'),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: hasData
                    ? FieldMapWidget(
                        rows: rows,
                        columns: columns,
                        measurements: measurements!,
                      )
                    : EmptyState(
                        icon: Icons.grid_off,
                        title: Strings.tr(locale, 'noGridData'),
                        message: Strings.tr(locale, 'noGridDataMsg'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime t) {
    final l = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.year)}/${two(l.month)}/${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
