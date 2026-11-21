import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/app_colors.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/core/theme/theme_provider.dart';
import 'package:fpl_lens/core/theme/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to calculate relative luminance according to WCAG 2.1 specifications.
double _calculateRelativeLuminance(Color color) {
  double srgbToLinear(double channel) {
    if (channel <= 0.04045) {
      return channel / 12.92;
    } else {
      return pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  final r = srgbToLinear(color.r);
  final g = srgbToLinear(color.g);
  final b = srgbToLinear(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Helper to calculate contrast ratio according to WCAG 2.1 specifications.
double _calculateContrastRatio(Color c1, Color c2) {
  final l1 = _calculateRelativeLuminance(c1);
  final l2 = _calculateRelativeLuminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Visual Redesign §3.3: WCAG 2.1 AA Contrast Measurements', () {
    test('Dark Accent on bgBase meets AA and AAA (>= 7.0:1)', () {
      final ratio = _calculateContrastRatio(AppColors.dark.accent, AppColors.dark.bgBase);
      expect(ratio, greaterThanOrEqualTo(7.0), reason: 'Ratio: $ratio');
      expect(ratio, closeTo(11.1, 0.5));
    });

    test('Dark textSecondary on bgSurface meets AA (>= 4.5:1)', () {
      final ratio = _calculateContrastRatio(AppColors.dark.textSecondary, AppColors.dark.bgSurface);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio: $ratio');
      expect(ratio, closeTo(9.2, 0.5));
    });

    test('Light Accent on bgBase meets AA (>= 4.5:1)', () {
      final ratio = _calculateContrastRatio(AppColors.light.accent, AppColors.light.bgBase);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio: $ratio');
      expect(ratio, closeTo(6.6, 0.5));
    });

    test('Light textPrimary on bgBase meets AAA (>= 7.0:1)', () {
      final ratio = _calculateContrastRatio(AppColors.light.textPrimary, AppColors.light.bgBase);
      expect(ratio, greaterThanOrEqualTo(7.0), reason: 'Ratio: $ratio');
      expect(ratio, closeTo(17.2, 0.5));
    });

    test('Dark textDisabled (#8A8A93) on bgSurface meets AA (>= 4.5:1)', () {
      final ratio = _calculateContrastRatio(AppColors.dark.textDisabled, AppColors.dark.bgSurface);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio: $ratio (passed replacement check)');
    });

    test('Light textDisabled (#71717A) on bgSurface meets AA (>= 4.5:1)', () {
      final ratio = _calculateContrastRatio(AppColors.light.textDisabled, AppColors.light.bgSurface);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio: $ratio');
    });
  });

  group('Visual Redesign §3.1: Theme Mode & Persistence', () {
    test('ThemeNotifier defaults to ThemeMode.system and updates without restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemeMode.system);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(prefs.getString('fpl_theme_mode'), 'dark');

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(prefs.getString('fpl_theme_mode'), 'light');
    });

    test('ThemeNotifier restores saved preference on restart', () async {
      SharedPreferences.setMockInitialValues({'fpl_theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();

      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemeMode.light);
    });

    test('MotionPolicyNotifier defaults to false, toggles, and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = MotionPolicyNotifier(prefs);
      expect(notifier.state, isFalse);

      await notifier.setReduceMotion(true);
      expect(notifier.state, isTrue);
      expect(prefs.getBool('fpl_reduce_motion'), isTrue);

      await notifier.setReduceMotion(false);
      expect(notifier.state, isFalse);
      expect(prefs.getBool('fpl_reduce_motion'), isFalse);
    });
  });

  group('Visual Redesign §4.1: Typography & Type Scale', () {
    test('Hero numeral has 64 sp, 800 weight and tabular figures', () {
      expect(AppTextStyles.heroNumeral.fontSize, 64.0);
      expect(AppTextStyles.heroNumeral.fontWeight, FontWeight.w800);
      expect(AppTextStyles.heroNumeral.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('Figure style has 18 sp, 700 weight and tabular figures', () {
      expect(AppTextStyles.figure.fontSize, 18.0);
      expect(AppTextStyles.figure.fontWeight, FontWeight.w700);
      expect(AppTextStyles.figure.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('Display has 36 sp and 800 weight', () {
      expect(AppTextStyles.display.fontSize, 36.0);
      expect(AppTextStyles.display.fontWeight, FontWeight.w800);
    });

    test('Title has 22 sp and 700 weight', () {
      expect(AppTextStyles.title.fontSize, 22.0);
      expect(AppTextStyles.title.fontWeight, FontWeight.w700);
    });
  });

  group('Visual Redesign §3.2 & §4.5: Theme Configuration & Extensions', () {
    test('AppTheme darkTheme contains AppColors.dark extension', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      final extension = theme.extension<AppColors>();
      expect(extension, isNotNull);
      expect(extension?.bgBase, AppColors.dark.bgBase);
      expect(extension?.accent, AppColors.dark.accent);
    });

    test('AppTheme lightTheme contains AppColors.light extension', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      final extension = theme.extension<AppColors>();
      expect(extension, isNotNull);
      expect(extension?.bgBase, AppColors.light.bgBase);
      expect(extension?.accent, AppColors.light.accent);
    });

    testWidgets('AppColors.of(context) dynamically returns dark or light palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('light_tree'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) {
              final colors = context.colors;
              expect(colors.bgBase, AppColors.light.bgBase);
              expect(colors.textPrimary, AppColors.light.textPrimary);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark_tree'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              final colors = context.colors;
              expect(colors.bgBase, AppColors.dark.bgBase);
              expect(colors.textPrimary, AppColors.dark.textPrimary);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}
