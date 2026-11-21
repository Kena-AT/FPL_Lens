import 'package:flutter/material.dart';

/// Design tokens for FPL Lens per Visual Redesign Design Document §3.2 & §4.
/// No raw colour, space, radius, or motion literals allowed in feature code.
abstract final class AppTokens {
  // --- Dark Mode Default Palette (§3.2) ---
  static const Color bgBase = Color(0xFF0B0B0C);
  static const Color bgSurface = Color(0xFF151518);
  static const Color bgElevated = Color(0xFF1E1E23);
  static const Color borderSubtle = Color(0xFF2A2A31);

  // --- Typography ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8BE);
  // Updated from #6B6B73 to #8A8A93 per §3.3 to pass 4.5:1 WCAG contrast
  static const Color textDisabled = Color(0xFF8A8A93);

  // --- The Single Accent (§3.2, §3.4) ---
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentOn = Color(0xFF0B0B0C);
  static const Color accentSoft = Color(0xFF0A6E85);

  // --- Status & Availability (§6) ---
  static const Color statusOk = Color(0xFF3DDC84);
  static const Color statusWarn = Color(0xFFFFB020);
  static const Color statusError = Color(0xFFFF4D5E);

  // --- Pitch Gradient (§3.2) ---
  static const Color pitchTop = Color(0xFF0F241A);
  static const Color pitchBottom = Color(0xFF07120D);
  static const List<Color> bgPitchGradient = [
    pitchTop,
    Color(0xFF0A1A13),
    pitchBottom,
  ];

  // --- Backward-Compatibility Aliases (during R1-R4 migration) ---
  static const Color neonPrimary = accent;
  static const Color neonDim = accentSoft;
  static const Color statusAvailable = statusOk;
  static const Color statusDoubtful = statusWarn;
  static const Color statusOut = statusError;
  // Gold tokens redirected to accent per §3.2 (no gold used)
  static const Color goldPrimary = accent;
  static const Color goldLight = accent;
  static const Color goldDark = accentSoft;

  // --- Spacing (dp) §4.2 ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double screenGutter = 16.0;

  // --- Corner Radii (dp) §4.2 ---
  static const double radiusSubtle = 4.0;
  static const double radiusBase = 8.0;
  static const double radiusCard = 12.0;
  static const double radiusModal = 16.0;
  static const double radiusPill = 999.0;

  // Backward-compatibility radius aliases
  static const double radiusChip = radiusBase;
  static const double radiusInput = 12.0;
  static const double radiusSheet = radiusModal;

  // --- Motion Durations (§4.2) ---
  static const Duration motionInstant = Duration.zero;
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionBase = Duration(milliseconds: 200);
  static const Duration motionSlow = Duration(milliseconds: 320);

  // Backward-compatibility motion aliases
  static const Duration motionMicro = motionFast;
  static const Duration motionReveal = Duration(milliseconds: 280);
  static const Duration motionHeroCount = Duration(milliseconds: 400);
  static const Duration motionScreen = Duration(milliseconds: 250);
  static const Duration motionPitch = Duration(milliseconds: 160);
  static const Duration motionSwap = motionBase;

  /// Returns effective duration respecting reduced motion settings.
  static Duration motion(BuildContext context, Duration defaultDuration) {
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return defaultDuration;
  }
}
