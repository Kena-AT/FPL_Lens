import 'package:flutter/material.dart';

/// Theme extension providing dynamic semantic color tokens for Light and Dark modes
/// per Visual Redesign Design Document §3.2.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color accent;
  final Color accentOn;
  final Color accentSoft;
  final Color statusOk;
  final Color statusWarn;
  final Color statusError;
  final Color pitchTop;
  final Color pitchBottom;

  const AppColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.accent,
    required this.accentOn,
    required this.accentSoft,
    required this.statusOk,
    required this.statusWarn,
    required this.statusError,
    required this.pitchTop,
    required this.pitchBottom,
  });

  /// Dark mode palette (§3.2)
  static const dark = AppColors(
    bgBase: Color(0xFF0B0B0C),
    bgSurface: Color(0xFF151518),
    bgElevated: Color(0xFF1E1E23),
    borderSubtle: Color(0xFF2A2A31),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8B8BE),
    textDisabled: Color(0xFF8A8A93),
    accent: Color(0xFF00D4FF),
    accentOn: Color(0xFF0B0B0C),
    accentSoft: Color(0xFF0A6E85),
    statusOk: Color(0xFF3DDC84),
    statusWarn: Color(0xFFFFB020),
    statusError: Color(0xFFFF4D5E),
    pitchTop: Color(0xFF0F241A),
    pitchBottom: Color(0xFF07120D),
  );

  /// Light mode palette (§3.2)
  static const light = AppColors(
    bgBase: Color(0xFFF5F4EF),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFECEBE4),
    borderSubtle: Color(0xFFD9D8D0),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF4A4A52),
    // Adjusted from #7A7A82 to #71717A to exceed 4.5:1 contrast on #FFFFFF (measures 4.88:1)
    textDisabled: Color(0xFF71717A),
    accent: Color(0xFF005F73),
    accentOn: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD5EEF3),
    statusOk: Color(0xFF1B7F4B),
    statusWarn: Color(0xFF8A5A00),
    statusError: Color(0xFFB3261E),
    pitchTop: Color(0xFFDCEBDD),
    pitchBottom: Color(0xFFC4DCC6),
  );

  /// Helper to access AppColors from BuildContext.
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? dark;
  }

  /// Whether this color palette corresponds to dark mode.
  bool get isDark => bgBase.computeLuminance() < 0.5;

  /// Glass background fill per §4.4 (70% opacity bgSurface).
  Color get bgGlass => bgSurface.withValues(alpha: 0.70);

  /// Glass edge border per §4.4 (1dp, white at 12% in dark, black at 8% in light).
  Color get borderGlass => isDark ? const Color(0x1FFFFFFF) : const Color(0x14000000);

  @override
  AppColors copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgElevated,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? accent,
    Color? accentOn,
    Color? accentSoft,
    Color? statusOk,
    Color? statusWarn,
    Color? statusError,
    Color? pitchTop,
    Color? pitchBottom,
  }) {
    return AppColors(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentOn: accentOn ?? this.accentOn,
      accentSoft: accentSoft ?? this.accentSoft,
      statusOk: statusOk ?? this.statusOk,
      statusWarn: statusWarn ?? this.statusWarn,
      statusError: statusError ?? this.statusError,
      pitchTop: pitchTop ?? this.pitchTop,
      pitchBottom: pitchBottom ?? this.pitchBottom,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      statusOk: Color.lerp(statusOk, other.statusOk, t)!,
      statusWarn: Color.lerp(statusWarn, other.statusWarn, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      pitchTop: Color.lerp(pitchTop, other.pitchTop, t)!,
      pitchBottom: Color.lerp(pitchBottom, other.pitchBottom, t)!,
    );
  }
}

/// Convenient BuildContext extension for `context.colors`.
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors.of(this);
}
