// This file previously defined custom Color and Offset classes that conflicted with Flutter's types.
// They have been removed. Use Flutter's Color and Offset from dart:ui or material.dart everywhere.

// If you need color utility functions, define them here using Flutter's Color type.
// Example:
// import 'package:flutter/material.dart';
// Color? parseColor(String? hex) { ... }

import 'package:flutter/material.dart';

/// Parses a color from a [Color] or hex [String] (e.g., '#RRGGBB' or '#AARRGGBB').
Color? parseColor(dynamic color, [double? opacity]) {
  if (color == null) return null;
  if (color is Color) {
    return opacity != null ? color.withValues(alpha: opacity) : color;
  }
  if (color is String) {
    String hex = color.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    int val = int.tryParse(hex, radix: 16) ?? 0xFFFFFFFF;
    return Color(val).withValues(alpha: opacity ?? 1.0);
  }
  return null;
}

extension ColorWithValues on Color {
  Color withValues({required double alpha}) => withOpacity(alpha);
}
