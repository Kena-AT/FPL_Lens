import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/widgets/availability_badge.dart';

void main() {
  Widget buildTestable(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('D10 AvailabilityBadge Widget Tests', () {
    testWidgets('renders Fit variant correctly', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AvailabilityBadge(variant: AvailabilityVariant.fit),
        ),
      );

      expect(find.text('Fit'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders Doubtful variant with chance of playing', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AvailabilityBadge(
            variant: AvailabilityVariant.doubtful,
            chanceOfPlaying: 75,
          ),
        ),
      );

      expect(find.text('Doubtful, 75%'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('renders Doubtful variant without chance of playing', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AvailabilityBadge(variant: AvailabilityVariant.doubtful),
        ),
      );

      expect(find.text('Doubtful'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('renders Injured variant correctly', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AvailabilityBadge(variant: AvailabilityVariant.injured),
        ),
      );

      expect(find.text('Injured'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('renders Suspended variant correctly', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AvailabilityBadge(variant: AvailabilityVariant.suspended),
        ),
      );

      expect(find.text('Suspended'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('renders FPL news text and source when showNews is true', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AvailabilityBadge(
            variant: AvailabilityVariant.doubtful,
            chanceOfPlaying: 50,
            news: 'Hamstring injury - 50% chance of playing',
            newsTimestamp: 'Oct 19, 2026',
            showNews: true,
          ),
        ),
      );

      expect(find.text('Doubtful, 50%'), findsOneWidget);
      expect(find.text('Hamstring injury - 50% chance of playing'), findsOneWidget);
      expect(find.text('Source: FPL'), findsOneWidget);
      expect(find.text('Oct 19, 2026'), findsOneWidget);
    });

    testWidgets('factory fromStatus parses correctly', (tester) async {
      final badgeA = AvailabilityBadge.fromStatus(status: 'a');
      expect(badgeA.variant, AvailabilityVariant.fit);

      final badgeD = AvailabilityBadge.fromStatus(status: 'd', chanceOfPlaying: 25);
      expect(badgeD.variant, AvailabilityVariant.doubtful);
      expect(badgeD.chanceOfPlaying, 25);

      final badgeI = AvailabilityBadge.fromStatus(status: 'i');
      expect(badgeI.variant, AvailabilityVariant.injured);

      final badgeS = AvailabilityBadge.fromStatus(status: 's');
      expect(badgeS.variant, AvailabilityVariant.suspended);
    });
  });
}
