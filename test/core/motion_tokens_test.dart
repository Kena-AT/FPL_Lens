import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/tokens.dart';

void main() {
  group('Part I Motion Tokens Audit', () {
    test('Enforces exact duration values per Part I', () {
      expect(AppTokens.motionMicro, const Duration(milliseconds: 150));
      expect(AppTokens.motionScreen, const Duration(milliseconds: 250));
      expect(AppTokens.motionPitch, const Duration(milliseconds: 400));
      expect(AppTokens.motionSwap, const Duration(milliseconds: 200));
    });

    testWidgets('AppTokens.motion returns normal duration when animations enabled', (tester) async {
      late Duration effectiveMicro;
      late Duration effectiveScreen;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              effectiveMicro = AppTokens.motion(context, AppTokens.motionMicro);
              effectiveScreen = AppTokens.motion(context, AppTokens.motionScreen);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(effectiveMicro, const Duration(milliseconds: 150));
      expect(effectiveScreen, const Duration(milliseconds: 250));
    });

    testWidgets('AppTokens.motion returns Duration.zero when MediaQuery.disableAnimations is true', (tester) async {
      late Duration effectiveMicro;
      late Duration effectiveScreen;
      late Duration effectivePitch;
      late Duration effectiveSwap;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                effectiveMicro = AppTokens.motion(context, AppTokens.motionMicro);
                effectiveScreen = AppTokens.motion(context, AppTokens.motionScreen);
                effectivePitch = AppTokens.motion(context, AppTokens.motionPitch);
                effectiveSwap = AppTokens.motion(context, AppTokens.motionSwap);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(effectiveMicro, Duration.zero);
      expect(effectiveScreen, Duration.zero);
      expect(effectivePitch, Duration.zero);
      expect(effectiveSwap, Duration.zero);
    });
  });
}
