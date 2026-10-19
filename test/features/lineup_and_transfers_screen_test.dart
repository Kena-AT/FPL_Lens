import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/features/lineup/screens/lineup_screen.dart';
import 'package:fpl_lens/features/transfers/screens/transfer_lab_screen.dart';

void main() {
  Widget buildTestScreen(Widget screen, double width, double height) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: screen,
          ),
        ),
      ),
    );
  }

  group('P10 LineupScreen Responsiveness', () {
    for (final width in [360.0, 430.0]) {
      testWidgets('Renders properly at width $width dp in dark theme', (tester) async {
        tester.view.physicalSize = Size(width, 800.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestScreen(const LineupScreen(), width, 800.0));
        await tester.pumpAndSettle();

        expect(find.byType(LineupScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('P12 TransferLabScreen Responsiveness', () {
    for (final width in [360.0, 430.0]) {
      testWidgets('Renders properly at width $width dp in dark theme', (tester) async {
        tester.view.physicalSize = Size(width, 800.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestScreen(const TransferLabScreen(), width, 800.0));
        await tester.pumpAndSettle();

        expect(find.byType(TransferLabScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
