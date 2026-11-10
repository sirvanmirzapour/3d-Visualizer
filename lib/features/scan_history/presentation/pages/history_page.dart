import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/scan_repository.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final scansAsync = ref.watch(savedScansProvider);

    return Scaffold(
      appBar: AppBar(title: Text(Strings.tr(locale, 'history'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: scansAsync.when(
            data: (scans) {
              if (scans.isEmpty) {
                return Center(
                  child: EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: Strings.tr(locale, 'noSavedScans'),
                    message: Strings.tr(locale, 'noSavedScansMsg'),
                  ),
                );
              }
              return ListView.separated(
                itemCount: scans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = scans[index];
                  final complete = s.complete;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.scanDetail,
                      arguments: {
                        'title': 'Scan ${scans.length - index}',
                        'date': s.createdAt,
                        'rows': s.rows,
                        'columns': s.columns,
                        'points': s.points,
                        'status': complete ? 'Complete' : 'Incomplete',
                        'measurements': s.measurements,
                      },
                    ),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.grid_on, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scan ${scans.length - index}', style: AppTextStyles.title.copyWith(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_fmtDate(s.createdAt)} • ${s.rows}×${s.columns} • ${s.points} ${Strings.tr(locale, 'points')}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: complete
                                ? Strings.tr(locale, 'complete')
                                : Strings.tr(locale, 'incomplete'),
                            color: complete ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: Strings.tr(locale, 'noSavedScans'),
                message: '$e',
              ),
            ),
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
