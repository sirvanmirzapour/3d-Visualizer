import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../live_scan/presentation/widgets/heatmap_widget.dart';

class ScanDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final int rows;
  final int columns;
  final int points;
  final String status;

  const ScanDetailPage({
    super.key,
    required this.title,
    required this.date,
    required this.rows,
    required this.columns,
    required this.points,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Details')),
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
                          label: status,
                          color: status == 'Complete' ? AppColors.success : AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Date: $date', style: AppTextStyles.caption),
                    Text('Grid: $rows × $columns', style: AppTextStyles.caption),
                    Text('Points: $points', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SectionHeader(
                title: 'Saved Heatmap',
                subtitle: 'Structure prepared for future stored data rendering',
              ),
              const SizedBox(height: 8),
              AppCard(
                child: rows > 0 && columns > 0
                    ? HeatmapWidget(rows: rows, columns: columns)
                    : const EmptyState(
                        icon: Icons.grid_off,
                        title: 'No grid data',
                        message: 'Detailed visualization will be available in future phases.',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
