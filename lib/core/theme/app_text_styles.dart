import 'package:flutter/material.dart';

/// Text styles without hardcoded colors. The color is inherited from the
/// ambient DefaultTextStyle, which is set by the active theme (dark or light)
/// so text stays readable in both themes.
class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle valueLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );
}
