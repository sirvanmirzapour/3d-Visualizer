import 'package:flutter/material.dart';

import '../painters/heatmap_grid_painter.dart';

/// Heatmap display placeholder for Phase 1.
/// Designed to accept grid dimensions now and real measurement data/modes in later phases.
class HeatmapWidget extends StatelessWidget {
  final int rows;
  final int columns;

  const HeatmapWidget({
    super.key,
    required this.rows,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: columns / rows,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          boundaryMargin: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101319),
              border: Border.all(color: const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: HeatmapGridPainter(rows: rows, columns: columns),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
