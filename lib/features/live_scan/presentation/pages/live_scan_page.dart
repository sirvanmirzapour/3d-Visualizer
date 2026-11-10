import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../widgets/heatmap_widget.dart';

class LiveScanPage extends StatefulWidget {
  final int rows;
  final int columns;
  final bool embedded;

  const LiveScanPage({
    super.key,
    required this.rows,
    required this.columns,
  }) : embedded = false;

  const LiveScanPage.embedded({super.key})
      : rows = AppConstants.defaultRows,
        columns = AppConstants.defaultColumns,
        embedded = true;

  @override
  State<LiveScanPage> createState() => _LiveScanPageState();
}

class _LiveScanPageState extends State<LiveScanPage> {
  bool _uiRunning = false;

  void _showUiOnly(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.rows * widget.columns;
    const received = 0;
    final remaining = total - received;
    const progress = 0.0;

    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) _embeddedIntro(context),
            if (widget.embedded) const SizedBox(height: 12),
            _header(total),
            const SizedBox(height: 12),
            _valueCard(),
            const SizedBox(height: 12),
            const SectionHeader(
              title: 'Heatmap',
              subtitle: 'Grid structure ready for future measurement rendering',
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeatmapWidget(rows: widget.rows, columns: widget.columns),
                  const SizedBox(height: 8),
                  const Text(
                    'Pinch to zoom and drag to inspect the grid.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _infoSection(total, received, remaining, progress),
            const SizedBox(height: 12),
            _controls(context),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Scan')),
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scan'),
      ),
      body: content,
    );
  }

  Widget _embeddedIntro(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready for a new session', style: AppTextStyles.title),
                SizedBox(height: 4),
                Text(
                  'Configure dimensions to open a dedicated live scan view.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  Widget _header(int total) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Live Scan', style: AppTextStyles.headline),
              ),
              StatusPill(
                label: _uiRunning ? 'Preparing' : 'Idle',
                color: _uiRunning ? AppColors.warning : AppColors.secondary,
                icon: _uiRunning ? Icons.hourglass_top : Icons.pause_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grid: ${widget.rows} × ${widget.columns} ($total points)',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 4),
          const Text('Scan status: Waiting for hardware integration', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _valueCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Latest Value',
            subtitle: 'Real-time measurement placeholder',
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  'Waiting for data',
                  style: AppTextStyles.valueLarge.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No device data available in Phase 1',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(int total, int received, int remaining, double progress) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Scan Information',
            subtitle: 'Progress tracking structure',
          ),
          const SizedBox(height: 12),
          _row('Total Points', '$total'),
          _row('Received Points', '$received'),
          _row('Remaining Points', '$remaining'),
          _row('Progress Percentage', '${(progress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Controls',
            subtitle: 'UI actions only in Phase 1',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _uiRunning = true);
                  _showUiOnly('Scan start is a placeholder in Phase 1.');
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Scan'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _uiRunning = false);
                  _showUiOnly('Scan stop is a placeholder in Phase 1.');
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop Scan'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showUiOnly('Saving will be implemented in Phase 5.'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Scan'),
              ),
              if (!widget.embedded)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.scanConfig),
                  icon: const Icon(Icons.tune),
                  label: const Text('Change Grid'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
