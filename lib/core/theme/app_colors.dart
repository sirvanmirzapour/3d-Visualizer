import 'package:flutter/material.dart';

/// Industrial instrument palette.
/// Deep graphite surfaces, high-contrast text, and a signal-cyan accent with
/// amber/green/red semantic states — tuned for field use in bright and dark
/// environments.
class AppColors {
  // Surfaces (dark)
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF12161F);
  static const Color card = Color(0xFF171C26);
  static const Color cardBorder = Color(0xFF232B3A);

  // Brand / signal
  static const Color primary = Color(0xFF00E5C3); // signal teal
  static const Color primaryDeep = Color(0xFF00B8A0);
  static const Color secondary = Color(0xFF7C8CFF); // instrument indigo

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // Text
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFF9AA7BD);
  static const Color textMuted = Color(0xFF64748B);

  // Grid / technical lines
  static const Color gridLine = Color(0xFF1E2635);
  static const Color accentGlow = Color(0x3300E5C3);
}
