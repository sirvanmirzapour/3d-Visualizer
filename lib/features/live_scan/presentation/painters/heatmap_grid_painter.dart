import 'package:flutter/material.dart';

class HeatmapGridPainter extends CustomPainter {
  final int rows;
  final int columns;

  HeatmapGridPainter({required this.rows, required this.columns});

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || columns <= 0) return;
    final cellW = size.width / columns;
    final cellH = size.height / rows;

    final fill = Paint()..color = const Color(0xFF191F29);
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
  bool shouldRepaint(covariant HeatmapGridPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.columns != columns;
  }
}
