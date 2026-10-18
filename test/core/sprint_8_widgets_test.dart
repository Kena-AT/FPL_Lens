import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/widgets/freshness_label.dart';
import 'package:fpl_lens/core/widgets/history_row.dart';
import 'package:fpl_lens/core/widgets/player_card.dart';
import 'package:fpl_lens/core/widgets/skeleton_loader.dart';
import 'package:fpl_lens/core/widgets/stat_tile.dart';

void main() {
  group('Sprint 8 Shared Components Tests', () {
    testWidgets('FreshnessLabel displays fresh and stale text appropriately', (tester) async {
      final now = DateTime.now();

      // Fresh
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FreshnessLabel(lastUpdated: now.subtract(const Duration(minutes: 5))),
          ),
        ),
      );
      expect(find.textContaining('Updated 5 min ago'), findsOneWidget);

      // Stale
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FreshnessLabel(
              lastUpdated: now.subtract(const Duration(hours: 3)),
              staleThreshold: const Duration(hours: 1),
            ),
          ),
        ),
      );
      expect(find.textContaining('Stale: updated 3 h ago'), findsOneWidget);
    });

    testWidgets('StatTile displays standard, positive, and negative variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                StatTile(label: 'Total Points', value: '542'),
                StatTile(
                  label: 'Overall Rank',
                  value: '124,532',
                  variant: StatTileVariant.positive,
                ),
                StatTile(
                  label: 'GW Rank',
                  value: '1,452,000',
                  variant: StatTileVariant.negative,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total Points'), findsOneWidget);
      expect(find.text('542'), findsOneWidget);
      expect(find.text('Overall Rank'), findsOneWidget);
      expect(find.text('124,532'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('SkeletonLoader renders in static or animated mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 100, height: 20),
          ),
        ),
      );
      expect(find.byType(SkeletonLoader), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('HistoryRow displays Gameweek and Transfer variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HistoryRow.gameweek(
                  event: 7,
                  points: 65,
                  overallRank: 124532,
                  transferCost: 4,
                  pointsOnBench: 6,
                ),
                HistoryRow.transfer(
                  date: DateTime(2026, 10, 1),
                  playerInName: 'Saka',
                  playerInCostTenths: 100,
                  playerOutName: 'Eze',
                  playerOutCostTenths: 69,
                  priceSource: 'FROM_TRANSFER',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('GW 7'), findsOneWidget);
      expect(find.text('65 pts'), findsOneWidget);
      expect(find.text('Rank 124,532'), findsOneWidget);
      expect(find.text('-4'), findsOneWidget);

      expect(find.text('Saka'), findsOneWidget);
      expect(find.text('Eze'), findsOneWidget);
      expect(find.text('£10.0m'), findsOneWidget);
      expect(find.text('£6.9m'), findsOneWidget);
      expect(find.text('FROM_TRANSFER'), findsOneWidget);
    });

    testWidgets('PlayerCard renders player details, status, and captaincy badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                PlayerCard(
                  webName: 'Haaland',
                  positionText: 'FWD',
                  teamShortName: 'MCI',
                  nowCostTenths: 153,
                  priceSource: 'FROM_TRANSFER',
                  isCaptain: true,
                ),
                PlayerCard(
                  webName: 'Saka',
                  positionText: 'MID',
                  teamShortName: 'ARS',
                  nowCostTenths: 101,
                  priceSource: 'CONFIRM',
                  availability: PlayerAvailability.doubtful,
                  chanceOfPlaying: 75,
                ),
                PlayerCard(
                  webName: 'Alisson',
                  positionText: 'GK',
                  teamShortName: 'LIV',
                  nowCostTenths: 55,
                  availability: PlayerAvailability.injured,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Haaland'), findsOneWidget);
      expect(find.text('FWD'), findsOneWidget);
      expect(find.text('MCI'), findsOneWidget);
      expect(find.text('£15.3m'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      expect(find.text('Saka'), findsOneWidget);
      expect(find.text('Doubtful, 75%'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);

      expect(find.text('Alisson'), findsOneWidget);
      expect(find.text('Injured'), findsOneWidget);
    });
  });
}
