import 'package:flutter/material.dart';
import 'tokens.dart';

/// Typography tokens per Frontend Implementation Plan §B4.
abstract final class AppTextStyles {
  static const String fontDisplay = 'Quakiez';
  static const String fontBody = 'Inter';

  /// Splash wordmark, hero title only (40 / 44)
  static const TextStyle display = TextStyle(
    fontFamily: fontDisplay,
    fontFamilyFallback: [fontBody],
    fontSize: 40.0,
    height: 44.0 / 40.0,
    fontWeight: FontWeight.w400,
    color: AppTokens.textPrimary,
  );

  /// Screen titles (28 / 34)
  static const TextStyle title = TextStyle(
    fontFamily: fontDisplay,
    fontFamilyFallback: [fontBody],
    fontSize: 28.0,
    height: 34.0 / 28.0,
    fontWeight: FontWeight.w400,
    color: AppTokens.textPrimary,
  );

  /// Section headers, card titles (20 / 26)
  static const TextStyle headline = TextStyle(
    fontFamily: fontBody,
    fontSize: 20.0,
    height: 26.0 / 20.0,
    fontWeight: FontWeight.w600,
    color: AppTokens.textPrimary,
  );

  /// Body text (16 / 24)
  static const TextStyle body = TextStyle(
    fontFamily: fontBody,
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w400,
    color: AppTokens.textPrimary,
  );

  /// Field labels, chips, tab labels (13 / 18)
  static const TextStyle label = TextStyle(
    fontFamily: fontBody,
    fontSize: 13.0,
    height: 18.0 / 13.0,
    fontWeight: FontWeight.w500,
    color: AppTokens.textSecondary,
  );

  /// xP, prices, points, countdowns with tabular figures (16 / 24)
  static const TextStyle numeric = TextStyle(
    fontFamily: fontBody,
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppTokens.textPrimary,
  );

  /// Timestamps, footnotes (12 / 16)
  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w400,
    color: AppTokens.textSecondary,
  );
}
