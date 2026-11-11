import 'package:flutter/material.dart';

/// Shared color gradient used by smooth, square and 3D renderers so all views
/// use one consistent professional palette.
class HeatPalette {
  static const List<double> stops = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const List<Color> colors = [
    Color(0xFF0B1026),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
    Color(0xFFFACC15),
    Color(0xFFEF4444),
  ];

  static Color colorFor(double t) {
    if (t <= 0) return colors.first;
    if (t >= 1) return colors.last;
    for (var i = 0; i < stops.length - 1; i++) {
      if (t >= stops[i] && t <= stops[i + 1]) {
        final f = (t - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(colors[i], colors[i + 1], f)!;
      }
    }
    return colors.last;
  }
}
