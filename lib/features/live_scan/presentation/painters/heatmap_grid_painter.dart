import 'package:flutter/material.dart';

class HeatmapGridPainter extends CustomPainter {
  final int rows;
  final int columns;
  final List<num>? values;

  HeatmapGridPainter({required this.rows, required this.columns, this.values});

  static const Color _lowColor = Color(0xFF191F29);
  static const Color _highColor = Color(0xFF22D3EE);

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || columns <= 0) return;
    final cellW = size.width / columns;
    final cellH = size.height / rows;

    final stroke = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    double? minV;
    double? maxV;
    final vals = values;
    if (vals != null && vals.isNotEmpty) {
      for (final v in vals) {
        final d = v.toDouble();
        if (minV == null || d < minV) minV = d;
        if (maxV == null || d > maxV) maxV = d;
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final index = r * columns + c;
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);

        Color fill = _lowColor;
        if (vals != null && index < vals.length) {
          final v = vals[index].toDouble();
          double t = 0.5;
          if (minV != null && maxV != null && maxV > minV) {
            t = ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);
          }
          fill = Color.lerp(_lowColor, _highColor, t)!;
        }

        canvas.drawRect(rect, Paint()..color = fill);
        canvas.drawRect(rect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapGridPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.values != values;
  }
}
