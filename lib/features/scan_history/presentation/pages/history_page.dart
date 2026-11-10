import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HistoryItem>[]; // Phase 1: no real storage

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: items.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No saved scans',
                    message: 'Saved scan sessions will be listed here when storage is implemented.',
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.scanDetail,
                        arguments: item.toArgs(),
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
                                  Text(item.name, style: AppTextStyles.title.copyWith(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.date} • ${item.rows}×${item.columns} • ${item.points} points',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(
                              label: item.status,
                              color: item.status == 'Complete' ? AppColors.success : AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _HistoryItem {
  final String name;
  final String date;
  final int rows;
  final int columns;
  final int points;
  final String status;

  const _HistoryItem({
    required this.name,
    required this.date,
    required this.rows,
    required this.columns,
    required this.points,
    required this.status,
  });

  Map<String, dynamic> toArgs() => {
        'title': name,
        'date': date,
        'rows': rows,
        'columns': columns,
        'points': points,
        'status': status,
      };
}
