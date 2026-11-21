import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/tokens.dart';
import 'package:fpl_lens/core/theme/text_styles.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';

void main() {
  group('Design Tokens & AppTheme (Visual Redesign)', () {
    test('Colors are correctly defined dark palette', () {
      expect(AppTokens.bgBase, const Color(0xFF0B0B0C));
      expect(AppTokens.bgSurface, const Color(0xFF151518));
      expect(AppTokens.bgElevated, const Color(0xFF1E1E23));
      expect(AppTokens.accent, const Color(0xFF00D4FF));
      expect(AppTokens.neonPrimary, const Color(0xFF00D4FF));
      expect(AppTokens.statusAvailable, const Color(0xFF3DDC84));
      expect(AppTokens.statusDoubtful, const Color(0xFFFFB020));
      expect(AppTokens.statusOut, const Color(0xFFFF4D5E));
    });

    test('Spacing tokens match 4dp base scale', () {
      expect(AppTokens.space2, 2.0);
      expect(AppTokens.space4, 4.0);
      expect(AppTokens.space8, 8.0);
      expect(AppTokens.space12, 12.0);
      expect(AppTokens.space16, 16.0);
      expect(AppTokens.space24, 24.0);
      expect(AppTokens.space32, 32.0);
      expect(AppTokens.space48, 48.0);
      expect(AppTokens.screenGutter, 16.0);
    });

    test('Radius tokens adhere to specifications', () {
      expect(AppTokens.radiusSubtle, 4.0);
      expect(AppTokens.radiusBase, 8.0);
      expect(AppTokens.radiusCard, 12.0);
      expect(AppTokens.radiusModal, 16.0);
      expect(AppTokens.radiusPill, 999.0);
    });

    test('AppTheme generates pure dark theme with single electric cyan accent', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTokens.bgBase);
      expect(theme.colorScheme.surface, AppTokens.bgSurface);
      expect(theme.colorScheme.primary, AppTokens.accent);
      expect(theme.colorScheme.secondary, AppTokens.accentSoft);
    });

    test('Text styles configure correct font families and tabular figures', () {
      expect(AppTextStyles.display.fontFamily, 'Inter');
      expect(AppTextStyles.title.fontFamily, 'Inter');
      expect(AppTextStyles.headline.fontFamily, 'Inter');
      expect(AppTextStyles.body.fontFamily, 'Inter');
      expect(AppTextStyles.numeric.fontFeatures, isNotEmpty);
      expect(AppTextStyles.heroNumeral.fontFeatures, isNotEmpty);
      expect(AppTextStyles.figure.fontFeatures, isNotEmpty);
    });
  });
}
