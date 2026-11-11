import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight pseudo-3D surface view of the measured field, drawn with a
/// CustomPainter (no extra dependencies). Heights are the normalized values.
class Field3DWidget extends StatelessWidget {
  final int rows;
  final int columns;
  final List<num> measurements;

  const Field3DWidget({
    super.key,
    required this.rows,
    required this.columns,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 10,
          boundaryMargin: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101319),
              border: Border.all(color: const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: Field3DPainter(
                rows: rows,
                columns: columns,
                measurements: measurements,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class Field3DPainter extends CustomPainter {
  final int rows;
  final int columns;
  final List<num> measurements;

  Field3DPainter({required this.rows, required this.columns, required this.measurements});

  static const List<Color> _colors = [
    Color(0xFF0B1026),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
    Color(0xFFFACC15),
    Color(0xFFEF4444),
  ];

  double _norm(int index, double minV, double maxV) {
    if (index >= measurements.length) return 0;
    final v = measurements[index].toDouble();
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    return ((v - minV) / span).clamp(0.0, 1.0);
  }

  Color _colorFor(double t) {
    if (t <= 0) return _colors.first;
    if (t >= 1) return _colors.last;
    const stops = [0.0, 0.25, 0.5, 0.75, 1.0];
    for (var i = 0; i < stops.length - 1; i++) {
      if (t >= stops[i] && t <= stops[i + 1]) {
        final f = (t - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(_colors[i], _colors[i + 1], f)!;
      }
    }
    return _colors.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || columns <= 0 || measurements.isEmpty) return;

    double minV = measurements.first.toDouble();
    double maxV = measurements.first.toDouble();
    for (final v in measurements) {
      final d = v.toDouble();
      if (d < minV) minV = d;
      if (d > maxV) maxV = d;
    }

    final rx = -0.85;
    final ry = -0.55;
    final cosX = math.cos(rx);
    final sinX = math.sin(rx);
    final cosY = math.cos(ry);
    final sinY = math.sin(ry);
    final scale = size.shortestSide * 0.34;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final h = (rows - 1) / 2;
    final w = (columns - 1) / 2;

    Offset project(double gx, double gy, double z) {
      final x = gx - w;
      final y = gy - h;
      final y1 = y * cosX - z * sinX;
      final z1 = y * sinX + z * cosX;
      final x2 = x * cosY + z1 * sinY;
      return Offset(cx + x2 * scale, cy - y1 * scale);
    }

    double heightAt(int r, int c) {
      if (r < 0 || c < 0 || r >= rows || c >= columns) return 0;
      return _norm(r * columns + c, minV, maxV) * 2.0;
    }

    // Build quads with average depth for painter's-order sorting.
    final quads = <({double depth, Path path, Color color})>[];
    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < columns - 1; c++) {
        final i = r * columns + c;
        if (i >= measurements.length) continue;
        final z00 = heightAt(r, c);
        final z10 = heightAt(r, c + 1);
        final z11 = heightAt(r + 1, c + 1);
        final z01 = heightAt(r + 1, c);

        final p00 = project(c.toDouble(), r.toDouble(), z00);
        final p10 = project((c + 1).toDouble(), r.toDouble(), z10);
        final p11 = project((c + 1).toDouble(), (r + 1).toDouble(), z11);
        final p01 = project(c.toDouble(), (r + 1).toDouble(), z01);

        final t = (z00 + z10 + z11 + z01) / 8.0;
        final depth = (p00.dy + p10.dy + p11.dy + p01.dy) / 4.0;

        final path = Path()
          ..moveTo(p00.dx, p00.dy)
          ..lineTo(p10.dx, p10.dy)
          ..lineTo(p11.dx, p11.dy)
          ..lineTo(p01.dx, p01.dy)
          ..close();

        quads.add((depth: depth, path: path, color: _colorFor(t)));
      }
    }

    quads.sort((a, b) => a.depth.compareTo(b.depth));

    final stroke = Paint()
      ..color = const Color(0x66334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final q in quads) {
      canvas.drawPath(q.path, Paint()..color = q.color);
      canvas.drawPath(q.path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant Field3DPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.measurements != measurements;
  }
}
