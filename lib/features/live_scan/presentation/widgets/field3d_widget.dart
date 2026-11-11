import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../painters/heat_palette.dart';

/// Professional-looking interactive 3D field view.
///
/// Gestures are handled manually (no InteractiveViewer) to avoid conflicts:
///  - drag -> rotate the surface
///  - pinch -> zoom
class Field3DWidget extends StatefulWidget {
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
  State<Field3DWidget> createState() => _Field3DWidgetState();
}

class _Field3DWidgetState extends State<Field3DWidget> {
  double _rx = -0.9;
  double _ry = -0.6;
  double _zoom = 1;
  double _baseZoom = 1;
  Offset? _lastFocal;

  void _onScaleStart(ScaleStartDetails d) {
    _baseZoom = _zoom;
    _lastFocal = d.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final last = _lastFocal;
    if (last != null) {
      final dx = d.focalPoint.dx - last.dx;
      final dy = d.focalPoint.dy - last.dy;
      setState(() {
        _ry += dx * 0.008;
        _rx += dy * 0.008;
      });
    }
    _lastFocal = d.focalPoint;
    setState(() {
      _zoom = (_baseZoom * d.scale).clamp(0.5, 8.0);
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _lastFocal = null;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F1C),
              border: Border.all(color: const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: Field3DPainter(
                rows: widget.rows,
                columns: widget.columns,
                measurements: widget.measurements,
                rx: _rx,
                ry: _ry,
                zoom: _zoom,
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
  final double rx;
  final double ry;
  final double zoom;

  Field3DPainter({
    required this.rows,
    required this.columns,
    required this.measurements,
    required this.rx,
    required this.ry,
    required this.zoom,
  });

  double _norm(int index, double minV, double maxV) {
    if (index >= measurements.length) return 0;
    final v = measurements[index].toDouble();
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    return ((v - minV) / span).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || columns <= 0) return;

    // ---- background vignette ------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = const RadialGradient(
        colors: [Color(0xFF111827), Color(0xFF0A0F1C)],
      ).createShader(Offset.zero & size),
    );

    // ---- data range ---------------------------------------------------------
    double minV = 0;
    double maxV = 1;
    if (measurements.isNotEmpty) {
      minV = measurements.first.toDouble();
      maxV = measurements.first.toDouble();
      for (final v in measurements) {
        final d = v.toDouble();
        if (d < minV) minV = d;
        if (d > maxV) maxV = d;
      }
    }

    // ---- projection setup ---------------------------------------------------
    final cosX = math.cos(rx);
    final sinX = math.sin(rx);
    final cosY = math.cos(ry);
    final sinY = math.sin(ry);
    final scale = size.shortestSide * 0.34 * zoom;
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

    // Smooth, high-resolution sampling via inverse-distance interpolation so the
    // surface is rendered with many small quads instead of one big square per cell.
    double sampleAt(double gx, double gy) {
      const eps = 1e-4;
      const radius = 2.2;
      final rowLo = (gy - radius).floor().clamp(0, rows - 1);
      final rowHi = (gy + radius).ceil().clamp(0, rows - 1);
      final colLo = (gx - radius).floor().clamp(0, columns - 1);
      final colHi = (gx + radius).ceil().clamp(0, columns - 1);
      double sw = 0;
      double sv = 0;
      for (var r = rowLo; r <= rowHi; r++) {
        final dy = gy - (r + 0.5);
        for (var c = colLo; c <= colHi; c++) {
          final i = r * columns + c;
          if (i >= measurements.length) continue;
          final dx = gx - (c + 0.5);
          final w = 1.0 / (dx * dx + dy * dy + eps);
          sw += w;
          sv += w * _norm(i, minV, maxV);
        }
      }
      return sw > 0 ? sv / sw : 0;
    }

    // ---- base grid plane ----------------------------------------------------
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var r = 0; r < rows; r++) {
      final a = project(0, r.toDouble(), 0);
      final b = project((columns - 1).toDouble(), r.toDouble(), 0);
      canvas.drawLine(a, b, r == 0 || r == rows - 1 ? axisPaint : gridPaint);
    }
    for (var c = 0; c < columns; c++) {
      final a = project(c.toDouble(), 0, 0);
      final b = project(c.toDouble(), (rows - 1).toDouble(), 0);
      canvas.drawLine(a, b, c == 0 || c == columns - 1 ? axisPaint : gridPaint);
    }

    if (measurements.isEmpty) return;

    // ---- high-resolution subdivided surface ----------------------------------
    // Use a target subdivision so each tile is small regardless of grid size.
    final subTarget = 72;
    final subCols = columns > 2 ? subTarget.clamp(16, 100) : columns;
    final subRows = rows > 2
        ? subTarget.clamp(16, 100)
        : rows;

    final quads = <({double depth, Path path, Color color})>[];
    for (var r = 0; r < subRows - 1; r++) {
      final gy0 = (r / (subRows - 1)) * (rows - 1);
      final gy1 = ((r + 1) / (subRows - 1)) * (rows - 1);
      for (var c = 0; c < subCols - 1; c++) {
        final gx0 = (c / (subCols - 1)) * (columns - 1);
        final gx1 = ((c + 1) / (subCols - 1)) * (columns - 1);

        final z00 = sampleAt(gx0, gy0) * 2.2;
        final z10 = sampleAt(gx1, gy0) * 2.2;
        final z11 = sampleAt(gx1, gy1) * 2.2;
        final z01 = sampleAt(gx0, gy1) * 2.2;

        final p00 = project(gx0, gy0, z00);
        final p10 = project(gx1, gy0, z10);
        final p11 = project(gx1, gy1, z11);
        final p01 = project(gx0, gy1, z01);

        final t = (z00 + z10 + z11 + z01) / 8.8;
        final depth = (p00.dy + p10.dy + p11.dy + p01.dy) / 4.0;

        final path = Path()
          ..moveTo(p00.dx, p00.dy)
          ..lineTo(p10.dx, p10.dy)
          ..lineTo(p11.dx, p11.dy)
          ..lineTo(p01.dx, p01.dy)
          ..close();

        quads.add((depth: depth, path: path, color: HeatPalette.colorFor(t)));
      }
    }

    quads.sort((a, b) => a.depth.compareTo(b.depth));

    final wire = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final q in quads) {
      canvas.drawPath(q.path, Paint()..color = q.color);
      canvas.drawPath(q.path, wire);
    }

    // ---- scale legend -------------------------------------------------------
    final legendPaint = Paint()
      ..color = const Color(0xFF0B1026)
      ..style = PaintingStyle.fill;
    final legendRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, size.height - 40, size.width - 24, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(legendRect, legendPaint);

    final barRect = Rect.fromLTWH(24, size.height - 32, size.width - 48, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          colors: HeatPalette.colors,
        ).createShader(barRect),
    );
  }

  @override
  bool shouldRepaint(covariant Field3DPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.measurements != measurements ||
        oldDelegate.rx != rx ||
        oldDelegate.ry != ry ||
        oldDelegate.zoom != zoom;
  }
}
