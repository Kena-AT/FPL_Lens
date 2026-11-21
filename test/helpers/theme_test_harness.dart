import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';

enum ThemeTestVariant {
  light,
  dark,
  textScale200,
}

/// Test harness helper class for Sprint R1/R2 widget testing across
/// Light, Dark, and 200% text scale variants.
abstract final class ThemeTestHarness {
  static Widget dark({
    required Widget child,
    MediaQueryData? mediaQueryData,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: mediaQueryData ?? const MediaQueryData(size: Size(360, 800)),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  static Widget light({
    required Widget child,
    MediaQueryData? mediaQueryData,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: MediaQuery(
          data: mediaQueryData ?? const MediaQueryData(size: Size(360, 800)),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  static Widget scale200({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2.0),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }
}

/// Legacy helper for verifying widgets across Light, Dark, and 200% text scale variants.
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
