import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/tokens.dart';

void main() {
  group('Part I Motion Tokens Audit (Visual Redesign §4.2)', () {
    test('Enforces exact duration values per redesign spec §4.2', () {
      expect(AppTokens.motionInstant, Duration.zero);
      expect(AppTokens.motionFast, const Duration(milliseconds: 120));
      expect(AppTokens.motionBase, const Duration(milliseconds: 200));
      expect(AppTokens.motionSlow, const Duration(milliseconds: 320));
      expect(AppTokens.motionMicro, const Duration(milliseconds: 120));
    });

    testWidgets('AppTokens.motion returns normal duration when animations enabled', (tester) async {
      late Duration effectiveFast;
      late Duration effectiveBase;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              effectiveFast = AppTokens.motion(context, AppTokens.motionFast);
              effectiveBase = AppTokens.motion(context, AppTokens.motionBase);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(effectiveFast, const Duration(milliseconds: 120));
      expect(effectiveBase, const Duration(milliseconds: 200));
    });

    testWidgets('AppTokens.motion returns Duration.zero when MediaQuery.disableAnimations is true', (tester) async {
      late Duration effectiveFast;
      late Duration effectiveBase;
      late Duration effectiveSlow;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                effectiveFast = AppTokens.motion(context, AppTokens.motionFast);
                effectiveBase = AppTokens.motion(context, AppTokens.motionBase);
                effectiveSlow = AppTokens.motion(context, AppTokens.motionSlow);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(effectiveFast, Duration.zero);
      expect(effectiveBase, Duration.zero);
      expect(effectiveSlow, Duration.zero);
    });
  });
}
