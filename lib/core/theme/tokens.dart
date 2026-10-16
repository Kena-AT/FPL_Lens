import 'package:flutter/material.dart';

/// Design tokens for FPL Lens per Frontend Implementation Plan §B4.
/// No raw colour, space, radius, or motion literals allowed in feature code.
abstract final class AppTokens {
  // --- Colours: Backgrounds ---
  static const Color bgBase = Color(0xFF0B0B0C);
  static const Color bgSurface = Color(0xFF151518);
  static const Color bgElevated = Color(0xFF1E1E23);
  static const List<Color> bgPitchGradient = [
    Color(0xFF0F241A),
    Color(0xFF0A1A13),
    Color(0xFF07120D),
  ];

  // --- Colours: Borders & Dividers ---
  static const Color borderSubtle = Color(0xFF2A2A31);

  // --- Colours: Typography ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8BE);
  static const Color textDisabled = Color(0xFF6B6B73);

  // --- Colours: Brand Accents ---
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8CC6A);
  static const Color goldDark = Color(0xFF9C7C1E);

  static const Color neonPrimary = Color(0xFF00D4FF);
  static const Color neonDim = Color(0xFF0A6E85);

  // --- Colours: Status ---
  static const Color statusAvailable = Color(0xFF3DDC84);
  static const Color statusDoubtful = Color(0xFFFFB020);
  static const Color statusOut = Color(0xFFFF4D5E);

  // --- Spacing (dp) ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double screenGutter = 16.0;

  static const double radiusChip = 8.0;
  static const double radiusInput = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusSheet = 16.0;
  static const double radiusModal = 16.0;
  static const double radiusPill = 9999.0;

  // --- Motion (ms) ---
  static const Duration motionMicro = Duration(milliseconds: 150);
  static const Duration motionScreen = Duration(milliseconds: 250);
  static const Duration motionPitch = Duration(milliseconds: 400);
  static const Duration motionSwap = Duration(milliseconds: 200);

  /// Returns effective duration respecting reduced motion settings.
  static Duration motion(BuildContext context, Duration defaultDuration) {
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return defaultDuration;
  }
}
