import 'package:flutter/material.dart';
import 'tokens.dart';

/// Heatmap ramp colour tokens per Frontend Implementation Plan §P21 and §B4.
/// Sequential 5-step ramp from bgElevated to goldPrimary with AA contrast text colours.
abstract final class HeatmapTokens {
  static const Color step1 = AppTokens.bgElevated; // Lowest
  static const Color step2 = Color(0xFF382F19);
  static const Color step3 = Color(0xFF6B551C);
  static const Color step4 = Color(0xFFA38228);
  static const Color step5 = AppTokens.goldPrimary; // Highest

  static const List<Color> ramp = [step1, step2, step3, step4, step5];

  /// Returns appropriate WCAG AA readable text colour for each step.
  static Color textColorForStep(int stepIndex) {
    // Upper steps (4, 5) have brighter gold fills and use dark text
    if (stepIndex >= 3) {
      return AppTokens.bgBase;
    }
    return AppTokens.textPrimary;
  }

  /// Bucket descriptions
  static const List<String> bucketNames = [
    'Low',
    'Medium-low',
    'Medium',
    'Medium-high',
    'High',
  ];
}
