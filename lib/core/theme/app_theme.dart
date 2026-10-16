import 'package:flutter/material.dart';
import 'tokens.dart';
import 'text_styles.dart';

/// App theme configuring ThemeData for FPL Lens.
/// Dark theme only per Frontend Implementation Plan §B4.
abstract final class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTokens.bgBase,
      colorScheme: const ColorScheme.dark(
        surface: AppTokens.bgSurface,
        onSurface: AppTokens.textPrimary,
        primary: AppTokens.goldPrimary,
        onPrimary: AppTokens.bgBase,
        secondary: AppTokens.neonPrimary,
        onSecondary: AppTokens.bgBase,
        error: AppTokens.statusOut,
        onError: AppTokens.textPrimary,
        outline: AppTokens.borderSubtle,
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppTokens.borderSubtle, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusCard)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.bgBase,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      dividerTheme: const DividerThemeData(
        color: AppTokens.borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),
      fontFamily: AppTextStyles.fontBody,
    );
  }
}
