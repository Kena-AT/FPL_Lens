import 'package:flutter/material.dart';
import 'tokens.dart';

/// Typography tokens per Visual Redesign Design Document §4.1.
/// Standardizes on system sans (Roboto on Android) with tabular figures for all numbers.
abstract final class AppTextStyles {
  static const String fontBody = 'Inter';
  static const String fontDisplay = 'Inter';

  /// Hero numeral (64 sp / 800) per §4.1
  /// Deadline countdown, projected total (xP)
  static const TextStyle heroNumeral = TextStyle(
    fontFamily: fontBody,
    fontSize: 64.0,
    height: 72.0 / 64.0,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppTokens.textPrimary,
  );

  /// Display (36 sp / 800) per §4.1
  /// Splash wordmark, screen hero titles
  static const TextStyle display = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 36.0,
    height: 44.0 / 36.0,
    fontWeight: FontWeight.w800,
    color: AppTokens.textPrimary,
  );

  /// Title (22 sp / 700) per §4.1
  /// Screen titles, card titles
  static const TextStyle title = TextStyle(
    fontFamily: fontBody,
    fontSize: 22.0,
    height: 28.0 / 22.0,
    fontWeight: FontWeight.w700,
    color: AppTokens.textPrimary,
  );

  /// Subtitle (16 sp / 600) per §4.1
  /// Player names, section headers
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontBody,
    fontSize: 16.0,
    height: 22.0 / 16.0,
    fontWeight: FontWeight.w600,
    color: AppTokens.textPrimary,
  );

  /// Headline alias (20 sp / 600) for backward compatibility
  static const TextStyle headline = TextStyle(
    fontFamily: fontBody,
    fontSize: 20.0,
    height: 26.0 / 20.0,
    fontWeight: FontWeight.w600,
    color: AppTokens.textPrimary,
  );

  /// Body (15 sp / 400) per §4.1
  /// Descriptions, messages
  static const TextStyle body = TextStyle(
    fontFamily: fontBody,
    fontSize: 15.0,
    height: 22.0 / 15.0,
    fontWeight: FontWeight.w400,
    color: AppTokens.textPrimary,
  );

  /// Label (12 sp / 600, uppercase, +0.8 tracking) per §4.1
  /// Small section labels, tile captions
  static const TextStyle label = TextStyle(
    fontFamily: fontBody,
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppTokens.textSecondary,
  );

  /// Figure (18 sp / 700, tabular) per §4.1
  /// Prices, points, deltas
  static const TextStyle figure = TextStyle(
    fontFamily: fontBody,
    fontSize: 18.0,
    height: 24.0 / 18.0,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppTokens.textPrimary,
  );

  /// Numeric alias (16 sp / 600, tabular)
  static const TextStyle numeric = TextStyle(
    fontFamily: fontBody,
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppTokens.textPrimary,
  );

  /// Caption (12 sp / 400) per §4.1
  /// Timestamps, footnotes
  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w400,
    color: AppTokens.textSecondary,
  );
}
