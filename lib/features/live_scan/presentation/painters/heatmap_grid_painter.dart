import 'package:flutter/material.dart';

import 'heat_palette.dart';

class HeatmapGridPainter extends CustomPainter {
  final int rows;
  final int columns;
  final List<num>? values;
  final bool showValues;

  HeatmapGridPainter({
    required this.rows,
    required this.columns,
    this.values,
    this.showValues = true,
  });

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
    final span = (minV != null && maxV != null) ? maxV - minV : 0.0;

    final fontSize = (cellW < cellH ? cellW : cellH) * 0.42;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final index = r * columns + c;
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);

        Color fill = HeatPalette.colors.first;
        if (vals != null && index < vals.length) {
          final v = vals[index].toDouble();
          var t = 0.0;
          if (span > 1e-9) {
            t = ((v - minV!) / span).clamp(0.0, 1.0);
          }
          fill = HeatPalette.colorFor(t);
        }

        canvas.drawRect(rect, Paint()..color = fill);
        canvas.drawRect(rect, stroke);

        if (vals != null && index < vals.length && showValues) {
          final textColor =
              fill.computeLuminance() > 0.4 ? const Color(0xFF0B1026) : const Color(0xFFF8FAFC);
          final tp = TextPainter(
            text: TextSpan(
              text: _fmt(vals[index]),
              style: TextStyle(
                color: textColor,
                fontSize: fontSize.clamp(7.0, 14.0),
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
          );
        }
      }
    }
  }

  String _fmt(num v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  bool shouldRepaint(covariant HeatmapGridPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.values != values ||
        oldDelegate.showValues != showValues;
  }
}
