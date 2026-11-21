import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';

enum ThemeTestVariant {
  light,
  dark,
  textScale200,
}

/// Test harness for verifying widgets across Light, Dark, and 200% text scale variants
/// per Visual Redesign Design Document §12 & §16 (Sprint R1).
Widget buildThemedTestWidget({
  required Widget child,
  ThemeTestVariant variant = ThemeTestVariant.dark,
  Size physicalSize = const Size(360, 800),
  List<Override> overrides = const [],
}) {
  ThemeMode mode = ThemeMode.dark;
  double textScale = 1.0;

  switch (variant) {
    case ThemeTestVariant.light:
      mode = ThemeMode.light;
      break;
    case ThemeTestVariant.dark:
      mode = ThemeMode.dark;
      break;
    case ThemeTestVariant.textScale200:
      mode = ThemeMode.dark;
      textScale = 2.0;
      break;
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: MediaQuery(
        data: MediaQueryData(
          size: physicalSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}
