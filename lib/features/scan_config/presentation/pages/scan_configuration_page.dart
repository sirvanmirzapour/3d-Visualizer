import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_widgets.dart';

class ScanConfigurationPage extends StatefulWidget {
  final int? initialRows;
  final int? initialColumns;

  const ScanConfigurationPage({
    super.key,
    this.initialRows,
    this.initialColumns,
  });

  @override
  State<ScanConfigurationPage> createState() => _ScanConfigurationPageState();
}

class _ScanConfigurationPageState extends State<ScanConfigurationPage> {
  late final TextEditingController _rowsController;
  late final TextEditingController _columnsController;
  final _formKey = GlobalKey<FormState>();

  int _rows = AppConstants.defaultRows;
  int _cols = AppConstants.defaultColumns;

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
    if (value == null || value.trim().isEmpty) return '$label is required';
    final n = int.tryParse(value);
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return '$label must be greater than 0';
    if (n < AppConstants.minGridSize || n > AppConstants.maxGridSize) {
      return '$label must be between ${AppConstants.minGridSize} and ${AppConstants.maxGridSize}';
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
      arguments: {'rows': rows, 'columns': cols},
    );
  }

  @override
  Widget build(BuildContext context) {
    final validRows = int.tryParse(_rowsController.text) ?? _rows;
    final validCols = int.tryParse(_columnsController.text) ?? _cols;
    final showPreview = validRows > 0 && validCols > 0 &&
        validRows <= AppConstants.maxGridSize && validCols <= AppConstants.maxGridSize;
    final total = (showPreview ? validRows * validCols : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Configuration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: _syncValues,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCard(
                  child: SectionHeader(
                    title: 'Grid Dimensions',
                    subtitle: 'Define the scan area size. Limits prevent excessive memory use.',
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
                              decoration: const InputDecoration(
                                labelText: 'Rows',
                                hintText: 'e.g. 10',
                              ),
                              validator: (v) => _validate(v, 'Rows'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _columnsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Columns',
                                hintText: 'e.g. 10',
                              ),
                              validator: (v) => _validate(v, 'Columns'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _summaryRow('Total Points', total > 0 ? '$total' : '—'),
                      _summaryRow('Allowed Range', '${AppConstants.minGridSize}–${AppConstants.maxGridSize} per axis'),
                      const SizedBox(height: 8),
                      const Text(
                        'Values of 0 or negative numbers are not allowed.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'Grid Preview',
                  subtitle: 'Neutral preview of scan cells (no measurement data)',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: showPreview
                      ? _GridPreview(rows: validRows, columns: validCols)
                      : const EmptyState(
                          icon: Icons.grid_off,
                          title: 'Invalid dimensions',
                          message: 'Enter valid rows and columns to see a preview.',
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.radar),
                    label: const Text('Start Scanning'),
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
    const maxCells = 400; // limit preview rendering cost
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
