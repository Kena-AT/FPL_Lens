import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/tokens.dart';
import 'package:fpl_lens/core/theme/text_styles.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';

void main() {
  group('Design Tokens & AppTheme', () {
    test('Colors are correctly defined dark palette', () {
      expect(AppTokens.bgBase, const Color(0xFF0B0B0C));
      expect(AppTokens.bgSurface, const Color(0xFF151518));
      expect(AppTokens.bgElevated, const Color(0xFF1E1E23));
      expect(AppTokens.goldPrimary, const Color(0xFFD4AF37));
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
      expect(AppTokens.radiusChip, 8.0);
      expect(AppTokens.radiusInput, 12.0);
      expect(AppTokens.radiusCard, 16.0);
      expect(AppTokens.radiusSheet, 16.0);
      expect(AppTokens.radiusModal, 16.0);
      expect(AppTokens.radiusPill, 9999.0);
    });

    test('AppTheme generates pure dark theme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTokens.bgBase);
      expect(theme.colorScheme.surface, AppTokens.bgSurface);
      expect(theme.colorScheme.primary, AppTokens.goldPrimary);
      expect(theme.colorScheme.secondary, AppTokens.neonPrimary);
    });

    test('Text styles configure correct font families and tabular figures', () {
      expect(AppTextStyles.display.fontFamily, 'Quakiez');
      expect(AppTextStyles.display.fontFamilyFallback, contains('Inter'));
      expect(AppTextStyles.title.fontFamily, 'Quakiez');
      expect(AppTextStyles.headline.fontFamily, 'Inter');
      expect(AppTextStyles.body.fontFamily, 'Inter');
      expect(AppTextStyles.numeric.fontFeatures, isNotEmpty);
    });
  });
}
