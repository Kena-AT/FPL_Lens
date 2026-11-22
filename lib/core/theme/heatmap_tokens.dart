import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Heatmap ramp colour tokens per Redesign Doc §8.11 and §3.2.
/// Sequential 5-step cyan ramp (higher projected points = stronger accent)
/// with AA contrast text colours in both Light and Dark modes.
abstract final class HeatmapTokens {
  // Static dark tokens for backwards compatibility
  static const Color step1 = Color(0xFF14242A); // Lowest
  static const Color step2 = Color(0xFF0A3F4D);
  static const Color step3 = Color(0xFF0A6E85); // accentSoft
  static const Color step4 = Color(0xFF00A2C7);
  static const Color step5 = Color(0xFF00D4FF); // accent

  static const List<Color> ramp = [step1, step2, step3, step4, step5];

  // Dynamic ramp adapting to theme context
  static List<Color> rampFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return ramp;
    }
    return const [
      Color(0xFFECEBE4), // bgElevated
      Color(0xFFE2F4F8),
      Color(0xFFD5EEF3), // accentSoft
      Color(0xFF67B7C7),
      Color(0xFF005F73), // accent
    ];
  }

  /// Returns appropriate WCAG AA readable text colour for each step.
  static Color textColorForStep(BuildContext context, int stepIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);
    if (isDark) {
      // Step 4 and 5 are high luminance electric cyan, text should be dark
      if (stepIndex >= 3) {
        return colors.bgBase;
      }
      return colors.textPrimary;
    } else {
      // In light mode, step 4 and 5 are dark cyan (#005F73), text should be white
      if (stepIndex >= 3) {
        return colors.accentOn;
      }
      return colors.textPrimary;
    }
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
