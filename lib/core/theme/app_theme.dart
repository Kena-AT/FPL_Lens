import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_styles.dart';
import 'tokens.dart';

/// App theme configuring ThemeData for FPL Lens.
/// Supports Dark and Light themes with AppColors extension per Visual Redesign Design Document §3.2.
abstract final class AppTheme {
  /// Dark theme per §3.2
  static ThemeData get darkTheme {
    const colors = AppColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.bgBase,
      colorScheme: ColorScheme.dark(
        surface: colors.bgSurface,
        onSurface: colors.textPrimary,
        primary: colors.accent,
        onPrimary: colors.accentOn,
        secondary: colors.accentSoft,
        onSecondary: colors.textPrimary,
        error: colors.statusError,
        onError: colors.accentOn,
        outline: colors.borderSubtle,
      ),
      extensions: const [colors],
      cardTheme: CardThemeData(
        color: colors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.borderSubtle, width: 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusCard)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accentSoft;
            }
            return colors.bgSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accent;
            }
            return colors.textSecondary;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.borderSubtle, width: 1.0),
          ),
        ),
      ),
      fontFamily: AppTextStyles.fontBody,
    );
  }

  /// Light theme per §3.2
  static ThemeData get lightTheme {
    const colors = AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.bgBase,
      colorScheme: ColorScheme.light(
        surface: colors.bgSurface,
        onSurface: colors.textPrimary,
        primary: colors.accent,
        onPrimary: colors.accentOn,
        secondary: colors.accentSoft,
        onSecondary: colors.textPrimary,
        error: colors.statusError,
        onError: colors.accentOn,
        outline: colors.borderSubtle,
      ),
      extensions: const [colors],
      cardTheme: CardThemeData(
        color: colors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.borderSubtle, width: 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusCard)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accentSoft;
            }
            return colors.bgSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accent;
            }
            return colors.textSecondary;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.borderSubtle, width: 1.0),
          ),
        ),
      ),
      fontFamily: AppTextStyles.fontBody,
    );
  }
}
