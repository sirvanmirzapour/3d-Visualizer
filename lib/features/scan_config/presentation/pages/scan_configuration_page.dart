import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';

class ScanConfigurationPage extends ConsumerStatefulWidget {
  final int? initialRows;
  final int? initialColumns;

  const ScanConfigurationPage({
    super.key,
    this.initialRows,
    this.initialColumns,
  });

  @override
  ConsumerState<ScanConfigurationPage> createState() => _ScanConfigurationPageState();
}

class _ScanConfigurationPageState extends ConsumerState<ScanConfigurationPage> {
  late final TextEditingController _rowsController;
  late final TextEditingController _columnsController;
  final _formKey = GlobalKey<FormState>();

  int _rows = AppConstants.defaultRows;
  int _cols = AppConstants.defaultColumns;
  bool _zigzag = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows ?? AppConstants.defaultRows;
    _cols = widget.initialColumns ?? AppConstants.defaultColumns;
    _rowsController = TextEditingController(text: _rows.toString());
    _columnsController = TextEditingController(text: _cols.toString());
  }

  @override
  void dispose() {
    _rowsController.dispose();
    _columnsController.dispose();
    super.dispose();
  }

  void _syncValues() {
    final r = int.tryParse(_rowsController.text);
    final c = int.tryParse(_columnsController.text);
    setState(() {
      _rows = r ?? _rows;
      _cols = c ?? _cols;
    });
  }

  String? _validate(String? value, String label) {
    final locale = ref.read(localeProvider);
    if (value == null || value.trim().isEmpty) {
      return '$label ${Strings.tr(locale, 'requireLabel')}';
    }
    final n = int.tryParse(value);
    if (n == null) return Strings.tr(locale, 'validNumber');
    if (n <= 0) return '$label ${Strings.tr(locale, 'greaterThanZero')}';
    if (n < AppConstants.minGridSize || n > AppConstants.maxGridSize) {
      return Strings.tr(locale, 'betweenRange', {
        'min': '${AppConstants.minGridSize}',
        'max': '${AppConstants.maxGridSize}',
      });
    }
    return null;
  }

  void _startScanning() {
    if (!_formKey.currentState!.validate()) return;
    final rows = int.parse(_rowsController.text);
    final cols = int.parse(_columnsController.text);
    Navigator.pushNamed(
      context,
      AppRoutes.liveScan,
      arguments: {'rows': rows, 'columns': cols, 'zigzag': _zigzag},
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final validRows = int.tryParse(_rowsController.text) ?? _rows;
    final validCols = int.tryParse(_columnsController.text) ?? _cols;
    final showPreview = validRows > 0 && validCols > 0 &&
        validRows <= AppConstants.maxGridSize && validCols <= AppConstants.maxGridSize;
    final total = (showPreview ? validRows * validCols : 0);

    return Scaffold(
      appBar: AppBar(title: Text(Strings.tr(locale, 'scanConfiguration'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: _syncValues,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: SectionHeader(
                    title: Strings.tr(locale, 'gridDimensions'),
                    subtitle: Strings.tr(locale, 'gridDimensionsSub'),
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rowsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(labelText: Strings.tr(locale, 'rows')),
                              validator: (v) => _validate(v, Strings.tr(locale, 'rows')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _columnsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(labelText: Strings.tr(locale, 'columns')),
                              validator: (v) => _validate(v, Strings.tr(locale, 'columns')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _summaryRow(Strings.tr(locale, 'totalPointsLabel'), total > 0 ? '$total' : '—'),
                      _summaryRow(
                        Strings.tr(locale, 'allowedRange'),
                        '${AppConstants.minGridSize}–${AppConstants.maxGridSize}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Strings.tr(locale, 'nonPositiveHint'),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(
                  title: Strings.tr(locale, 'movementPattern'),
                  subtitle: Strings.tr(locale, 'movementPatternSub'),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: [
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.swap_vert),
                            label: Text(Strings.tr(locale, 'patternStraight')),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.shuffle),
                            label: Text(Strings.tr(locale, 'patternZigzag')),
                          ),
                        ],
                        selected: {_zigzag},
                        onSelectionChanged: (s) => setState(() => _zigzag = s.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: _PatternPreview(
                          rows: showPreview ? validRows : 1,
                          columns: showPreview ? validCols : 1,
                          zigzag: _zigzag,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(
                  title: Strings.tr(locale, 'gridPreview'),
                  subtitle: Strings.tr(locale, 'gridPreviewSub'),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: showPreview
                      ? _GridPreview(rows: validRows, columns: validCols)
                      : EmptyState(
                          icon: Icons.grid_off,
                          title: Strings.tr(locale, 'invalidDimensions'),
                          message: Strings.tr(locale, 'invalidDimensionsMsg'),
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.radar),
                    label: Text(Strings.tr(locale, 'startScanning')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
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

class _GridPreview extends StatelessWidget {
  final int rows;
  final int columns;

  const _GridPreview({required this.rows, required this.columns});

  @override
  Widget build(BuildContext context) {
    const maxCells = 400;
    final total = rows * columns;
    final renderAll = total <= maxCells;
    final displayRows = renderAll ? rows : rows.clamp(1, 20);
    final displayCols = renderAll ? columns : columns.clamp(1, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: columns / rows,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _PreviewGridPainter(
                  rows: displayRows,
                  columns: displayCols,
                ),
              ),
            ),
          ),
        ),
        if (!renderAll) ...[
          const SizedBox(height: 8),
          Text(
            'Preview simplified for large grids ($rows×$columns = $total points).',
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}

class _PatternPreview extends StatelessWidget {
  final int rows;
  final int columns;
  final bool zigzag;

  const _PatternPreview({required this.rows, required this.columns, required this.zigzag});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PatternPainter(rows: rows, columns: columns, zigzag: zigzag),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final int rows;
  final int columns;
  final bool zigzag;

  _PatternPainter({required this.rows, required this.columns, required this.zigzag});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 4;
    const c = 5;
    final cellW = size.width / c;
    final cellH = size.height / r;
    final grid = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i <= r; i++) {
      canvas.drawLine(Offset(0, i * cellH), Offset(size.width, i * cellH), grid);
    }
    for (int i = 0; i <= c; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, size.height), grid);
    }

    final path = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = AppColors.primary;

    // Build the visit order for a 4x5 demo grid: straight = always left->right,
    // zigzag = alternate direction per row.
    final points = <Offset>[];
    for (int row = 0; row < r; row++) {
      for (int col = 0; col < c; col++) {
        final cc = zigzag && row.isOdd ? c - 1 - col : col;
        points.add(Offset((cc + 0.5) * cellW, (row + 0.5) * cellH));
      }
    }
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], path);
    }
    for (final p in points) {
      canvas.drawCircle(p, 3, dot);
    }
    // Start marker.
    canvas.drawCircle(points.first, 6, Paint()..color = AppColors.success);
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.zigzag != zigzag;
  }
}

class _PreviewGridPainter extends CustomPainter {
  final int rows;
  final int columns;

  _PreviewGridPainter({required this.rows, required this.columns});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / columns;
    final cellH = size.height / rows;
    final fill = Paint()..color = AppColors.surface.withValues(alpha: 0.35);
    final stroke = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewGridPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.columns != columns;
  }
}
