import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../live_scan/presentation/widgets/field3d_widget.dart';
import '../../../live_scan/presentation/widgets/field_map_widget.dart';

enum _DetailView { twoD, threeD }

class ScanDetailPage extends ConsumerStatefulWidget {
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
  ConsumerState<ScanDetailPage> createState() => _ScanDetailPageState();
}

class _ScanDetailPageState extends ConsumerState<ScanDetailPage> {
  _DetailView _view = _DetailView.twoD;
  bool _showValues = false;
  double _adjustment = 0;
  bool _applied = false;

  List<num> get _displayMeasurements {
    final base = widget.measurements!;
    if (_adjustment == 0) return base;
    final avg = base.fold<num>(0, (s, v) => s + v) / base.length;
    return base
        .map((v) => v > avg ? v + _adjustment : (v < avg ? v - _adjustment : v))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final complete = widget.status == 'Complete';
    final hasData = widget.measurements != null &&
        widget.measurements!.isNotEmpty &&
        widget.rows > 0 &&
        widget.columns > 0;

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
                        Expanded(child: Text(widget.title, style: AppTextStyles.headline)),
                        StatusPill(
                          label: complete
                              ? Strings.tr(locale, 'complete')
                              : Strings.tr(locale, 'incomplete'),
                          color: complete ? AppColors.success : AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${Strings.tr(locale, 'date')}: ${_fmtDate(widget.date)}', style: AppTextStyles.caption),
                    Text('${Strings.tr(locale, 'grid')}: ${widget.rows} × ${widget.columns}', style: AppTextStyles.caption),
                    Text('${Strings.tr(locale, 'points')}: ${widget.points}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: Strings.tr(locale, 'savedHeatmap'),
                      subtitle: Strings.tr(locale, 'savedHeatmapSub'),
                    ),
                  ),
                  if (hasData)
                    SegmentedButton<_DetailView>(
                      segments: const [
                        ButtonSegment(value: _DetailView.twoD, label: Text('2D')),
                        ButtonSegment(value: _DetailView.threeD, label: Text('3D')),
                      ],
                      selected: {_view},
                      onSelectionChanged: (s) => setState(() => _view = s.first),
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasData && _view == _DetailView.twoD)
                Row(
                  children: [
                    const Icon(Icons.numbers, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Strings.tr(locale, 'showValues'),
                        style: AppTextStyles.body,
                      ),
                    ),
                    Switch(
                      value: _showValues,
                      onChanged: (v) => setState(() => _showValues = v),
                    ),
                  ],
                ),
              if (hasData && _view == _DetailView.twoD) const SizedBox(height: 8),
              if (hasData && _view == _DetailView.twoD)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: Strings.tr(locale, 'adjustValues'),
                        subtitle: Strings.tr(locale, 'adjustValuesSub'),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('0')),
                          ButtonSegment(value: 5, label: Text('5')),
                          ButtonSegment(value: 10, label: Text('10')),
                          ButtonSegment(value: 15, label: Text('15')),
                        ],
                        selected: {_adjustment},
                        onSelectionChanged: (s) => setState(() {
                          _adjustment = s.first;
                          _applied = s.first != 0;
                        }),
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      ),
                      if (_applied) ...[
                        const SizedBox(height: 8),
                        Text(
                          Strings.tr(locale, 'adjustedNote'),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              if (hasData && _view == _DetailView.twoD) const SizedBox(height: 8),
              AppCard(
                child: hasData
                    ? _buildMap()
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

  Widget _buildMap() {
    final measurements = _displayMeasurements;
    if (_view == _DetailView.threeD) {
      return Field3DWidget(
        rows: widget.rows,
        columns: widget.columns,
        measurements: measurements,
      );
    }
    return FieldMapWidget(
      rows: widget.rows,
      columns: widget.columns,
      measurements: measurements,
      showValues: _showValues,
    );
  }

  String _fmtDate(DateTime t) {
    final l = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.year)}/${two(l.month)}/${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
