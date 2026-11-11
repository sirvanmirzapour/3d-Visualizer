import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../painters/heat_palette.dart';

class FieldMapWidget extends StatefulWidget {
  final int rows;
  final int columns;
  final List<num> measurements;
  final bool showValues;

  const FieldMapWidget({
    super.key,
    required this.rows,
    required this.columns,
    required this.measurements,
    this.showValues = true,
  });

  @override
  State<FieldMapWidget> createState() => _FieldMapWidgetState();
}

class _FieldMapWidgetState extends State<FieldMapWidget> {
  ui.Image? _image;
  List<num> _samples = const [];
  double _min = 0;
  double _max = 1;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant FieldMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measurements != widget.measurements ||
        oldWidget.rows != widget.rows ||
        oldWidget.columns != widget.columns) {
      _rebuild();
    }
  }

  void _rebuild() {
    final rows = widget.rows;
    final cols = widget.columns;
    final samples = widget.measurements.take(rows * cols).toList();
    _samples = samples;
    if (samples.length < 2) {
      setState(() => _image = null);
      return;
    }

    var mn = samples.first.toDouble();
    var mx = samples.first.toDouble();
    for (final v in samples) {
      final d = v.toDouble();
      if (d < mn) mn = d;
      if (d > mx) mx = d;
    }
    final span = (mx - mn).abs() < 1e-9 ? 1.0 : (mx - mn);
    _min = mn;
    _max = mx;

    const outW = 320;
    final outH = (outW * rows / cols).round().clamp(40, 560);

    final data = ByteData(outW * outH * 4);
    const eps = 1e-4;
    const radius = 2.5;
    final maxRow = rows - 1;
    final maxCol = cols - 1;

    for (var y = 0; y < outH; y++) {
      final gy = (y / outH) * rows;
      final rowLo = (gy - radius).floor().clamp(0, maxRow);
      final rowHi = (gy + radius).ceil().clamp(0, maxRow);
      for (var x = 0; x < outW; x++) {
        final gx = (x / outW) * cols;
        final colLo = (gx - radius).floor().clamp(0, maxCol);
        final colHi = (gx + radius).ceil().clamp(0, maxCol);

        double sw = 0;
        double sv = 0;
        for (var r = rowLo; r <= rowHi; r++) {
          final cy = r + 0.5;
          final dy = gy - cy;
          for (var c = colLo; c <= colHi; c++) {
            final i = r * cols + c;
            if (i >= samples.length) continue;
            final dx = gx - (c + 0.5);
            final w = 1.0 / (dx * dx + dy * dy + eps);
            sw += w;
            sv += w * samples[i].toDouble();
          }
        }

        final norm = sw > 0 ? sv / sw : mn;
        final t = ((norm - mn) / span).clamp(0.0, 1.0);
        final color = HeatPalette.colorFor(t.toDouble());
        final o = (y * outW + x) * 4;
        data.setUint8(o, (color.r * 255).round().clamp(0, 255).toInt());
        data.setUint8(o + 1, (color.g * 255).round().clamp(0, 255).toInt());
        data.setUint8(o + 2, (color.b * 255).round().clamp(0, 255).toInt());
        data.setUint8(o + 3, 255);
      }
    }

    ui.decodeImageFromPixels(
      data.buffer.asUint8List(),
      outW,
      outH,
      ui.PixelFormat.rgba8888,
      (img) {
        if (!mounted) return;
        setState(() => _image = img);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return AspectRatio(
        aspectRatio: widget.columns / widget.rows,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF191F29),
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Start receiving at least 2 points\nto render the field map',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: widget.columns / widget.rows,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 8,
              boundaryMargin: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101319),
                  border: Border.all(color: const Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RawImage(image: _image, fit: BoxFit.fill),
                    if (widget.showValues && _samples.isNotEmpty)
                      CustomPaint(
                        painter: _ValueOverlayPainter(
                          rows: widget.rows,
                          cols: widget.columns,
                          measurements: _samples,
                          minV: _min,
                          maxV: _max,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(_fmt(_min), style: _legendText),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: HeatPalette.colors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_fmt(_max), style: _legendText),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  static const TextStyle _legendText = TextStyle(
    color: Color(0xFF94A3B8),
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class _ValueOverlayPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<num> measurements;
  final double minV;
  final double maxV;

  _ValueOverlayPainter({
    required this.rows,
    required this.cols,
    required this.measurements,
    required this.minV,
    required this.maxV,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (measurements.isEmpty) return;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final fontSize = (cellW < cellH ? cellW : cellH) * 0.42;

    for (var i = 0; i < measurements.length; i++) {
      final r = i ~/ cols;
      final c = i % cols;
      final x = (c + 0.5) * cellW;
      final y = (r + 0.5) * cellH;
      final tp = TextPainter(
        text: TextSpan(
          text: _fmt(measurements[i]),
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: fontSize.clamp(7.0, 16.0),
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Color(0xFF000000), blurRadius: 3, offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  String _fmt(num v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  bool shouldRepaint(covariant _ValueOverlayPainter oldDelegate) {
    return oldDelegate.measurements != measurements ||
        oldDelegate.rows != rows ||
        oldDelegate.cols != cols;
  }
}
