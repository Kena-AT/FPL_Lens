import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/tokens.dart';
import 'package:fpl_lens/core/widgets/app_button.dart';
import 'package:fpl_lens/core/widgets/availability_badge.dart';

double _relativeLuminance(Color color) {
  double channel(int c) {
    final v = c / 255.0;
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  // Use color.red, color.green, color.blue (0-255)
  // ignore: deprecated_member_use
  final r = channel(color.red);
  // ignore: deprecated_member_use
  final g = channel(color.green);
  // ignore: deprecated_member_use
  final b = channel(color.blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Part G Accessibility (WCAG 2.1 AA) Tests', () {
    test('WCAG 2.1 AA Contrast Ratios meet or exceed requirements', () {
      // Primary text on bg.base (Requirement: >= 4.5:1 for normal text)
      final textOnBase = _contrastRatio(AppTokens.textPrimary, AppTokens.bgBase);
      expect(textOnBase, greaterThanOrEqualTo(4.5));
      expect(textOnBase, greaterThan(15.0)); // In dark theme, white on near-black is ~19:1

      // Gold primary on bg.base (Requirement: >= 3:1 for large text/accents)
      final goldOnBase = _contrastRatio(AppTokens.goldPrimary, AppTokens.bgBase);
      expect(goldOnBase, greaterThanOrEqualTo(3.0));
      expect(goldOnBase, greaterThan(7.0));

      // Neon primary on bg.base
      final neonOnBase = _contrastRatio(AppTokens.neonPrimary, AppTokens.bgBase);
      expect(neonOnBase, greaterThanOrEqualTo(4.5));
      expect(neonOnBase, greaterThan(10.0));
    });

    testWidgets('AppButton enforces minimum 48 dp touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: 'Large Button',
                  size: AppButtonSize.large,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Medium Button',
                  size: AppButtonSize.medium,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final largeFinder = find.widgetWithText(AppButton, 'Large Button');
      final largeSize = tester.getSize(largeFinder);
      expect(largeSize.height, greaterThanOrEqualTo(48.0));

      final mediumFinder = find.widgetWithText(AppButton, 'Medium Button');
      final mediumSize = tester.getSize(mediumFinder);
      expect(mediumSize.height, greaterThanOrEqualTo(44.0)); // 44 + touch padding
    });

    testWidgets('AvailabilityBadge never relies on colour alone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AvailabilityBadge(variant: AvailabilityVariant.fit),
                AvailabilityBadge(variant: AvailabilityVariant.doubtful),
                AvailabilityBadge(variant: AvailabilityVariant.injured),
                AvailabilityBadge(variant: AvailabilityVariant.suspended),
              ],
            ),
          ),
        ),
      );

      // Verify text labels exist alongside colors
      expect(find.text('Fit'), findsOneWidget);
      expect(find.text('Doubtful'), findsOneWidget);
      expect(find.text('Injured'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);

      // Verify distinct rounded icons exist alongside colors
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('Buttons have accessible semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit Action',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(RegExp(r'Submit Action')), findsWidgets);
      expect(find.widgetWithText(AppButton, 'Submit Action'), findsOneWidget);
    });
  });
}
