import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/core/widgets/bench_strip.dart';
import 'package:fpl_lens/core/widgets/candidate_picker.dart';
import 'package:fpl_lens/core/widgets/hit_warning.dart';
import 'package:fpl_lens/core/widgets/pitch_view.dart';
import 'package:fpl_lens/core/widgets/player_chip.dart';
import 'package:fpl_lens/core/widgets/stat_tile.dart';
import 'package:fpl_lens/core/widgets/xp_badge.dart';

void main() {
  const testPlayer = PlayerCandidate(
    fplId: 8,
    webName: 'Salah',
    position: 'MID',
    clubId: 3,
    priceTenths: 125,
    sellingPriceTenths: 125,
    xp: 8.5,
    pStart: 0.95,
    pSub: 0.05,
  );

  group('XpBadge (D9)', () {
    testWidgets('renders formatted xP correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XpBadge(xp: 6.4),
          ),
        ),
      );

      expect(find.text('6.4 xP'), findsOneWidget);
    });

    testWidgets('compact mode renders without xP suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XpBadge(xp: 3.2, isCompact: true, showLabel: false),
          ),
        ),
      );

      expect(find.text('3.2'), findsOneWidget);
    });
  });

  group('PlayerChip (D6)', () {
    testWidgets('renders player name, price, and position badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerChip(player: testPlayer),
          ),
        ),
      );

      expect(find.text('Salah'), findsOneWidget);
      expect(find.text('£12.5m'), findsOneWidget);
      expect(find.text('MID'), findsOneWidget);
    });

    testWidgets('renders captain and vice-captain badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerChip(player: testPlayer, isCaptain: true),
          ),
        ),
      );

      expect(find.text('C'), findsOneWidget);
    });
  });

  group('HitWarning (D15)', () {
    testWidgets('displays deduction and transfer excess message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HitWarning(
              hitCost: 4,
              transferCount: 2,
              freeTransfers: 1,
            ),
          ),
        ),
      );

      expect(find.text('Hit Penalty: -4 pts'), findsOneWidget);
      expect(find.text('1 transfer exceeds your free transfer allowance.'), findsOneWidget);
    });

    testWidgets('renders shrink when hitCost is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HitWarning(
              hitCost: 0,
              transferCount: 1,
              freeTransfers: 1,
            ),
          ),
        ),
      );

      expect(find.text('Hit Penalty'), findsNothing);
    });
  });

  group('BenchStrip (D8)', () {
    testWidgets('renders 4 bench slots with correct labels', (tester) async {
      final bench = [
        const PlayerCandidate(fplId: 2, webName: 'Turner', position: 'GK', clubId: 2, priceTenths: 40, sellingPriceTenths: 40, xp: 1.2, pStart: 0.1, pSub: 0.05),
        const PlayerCandidate(fplId: 7, webName: 'Burn', position: 'DEF', clubId: 5, priceTenths: 45, sellingPriceTenths: 45, xp: 3.5, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 12, webName: 'Rogers', position: 'MID', clubId: 7, priceTenths: 50, sellingPriceTenths: 50, xp: 4.5, pStart: 0.85, pSub: 0.1),
        const PlayerCandidate(fplId: 15, webName: 'Wood', position: 'FWD', clubId: 2, priceTenths: 60, sellingPriceTenths: 60, xp: 5.2, pStart: 0.82, pSub: 0.15),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BenchStrip(benchPlayers: bench),
          ),
        ),
      );

      expect(find.text('BENCH (SUBSTITUTION ORDER)'), findsOneWidget);
      expect(find.text('GK'), findsNWidgets(2)); // slot label + player position
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Turner'), findsOneWidget);
      expect(find.text('Wood'), findsOneWidget);
    });
  });

  group('PitchView (D7)', () {
    testWidgets('renders all starting XI players across pitch rows', (tester) async {
      final startingXi = [
        const PlayerCandidate(fplId: 1, webName: 'Raya', position: 'GK', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 4.8, pStart: 0.98, pSub: 0.05),
        const PlayerCandidate(fplId: 3, webName: 'Gabriel', position: 'DEF', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 5.0, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 4, webName: 'Saliba', position: 'DEF', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 4.9, pStart: 0.96, pSub: 0.05),
        const PlayerCandidate(fplId: 5, webName: 'Trent', position: 'DEF', clubId: 3, priceTenths: 70, sellingPriceTenths: 70, xp: 6.2, pStart: 0.92, pSub: 0.05),
        const PlayerCandidate(fplId: 6, webName: 'Gvardiol', position: 'DEF', clubId: 4, priceTenths: 60, sellingPriceTenths: 60, xp: 5.1, pStart: 0.88, pSub: 0.05),
        const PlayerCandidate(fplId: 8, webName: 'Salah', position: 'MID', clubId: 3, priceTenths: 125, sellingPriceTenths: 125, xp: 8.5, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 9, webName: 'Saka', position: 'MID', clubId: 1, priceTenths: 100, sellingPriceTenths: 100, xp: 7.8, pStart: 0.94, pSub: 0.05),
        const PlayerCandidate(fplId: 10, webName: 'Palmer', position: 'MID', clubId: 6, priceTenths: 105, sellingPriceTenths: 105, xp: 8.0, pStart: 0.92, pSub: 0.05),
        const PlayerCandidate(fplId: 11, webName: 'Gordon', position: 'MID', clubId: 5, priceTenths: 75, sellingPriceTenths: 75, xp: 5.5, pStart: 0.89, pSub: 0.05),
        const PlayerCandidate(fplId: 13, webName: 'Haaland', position: 'FWD', clubId: 4, priceTenths: 150, sellingPriceTenths: 150, xp: 9.0, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 14, webName: 'Watkins', position: 'FWD', clubId: 7, priceTenths: 90, sellingPriceTenths: 90, xp: 6.8, pStart: 0.90, pSub: 0.05),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PitchView(
              startingXi: startingXi,
              captain: startingXi[9], // Haaland
              viceCaptain: startingXi[5], // Salah
            ),
          ),
        ),
      );

      expect(find.text('Raya'), findsOneWidget);
      expect(find.text('Haaland'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
    });
  });

  group('CandidatePicker (D12)', () {
    testWidgets('renders candidates list within budget', (tester) async {
      final pool = [
        const PlayerCandidate(fplId: 101, webName: 'Haaland', position: 'FWD', clubId: 4, priceTenths: 150, sellingPriceTenths: 150, xp: 9.0, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 102, webName: 'Salah', position: 'MID', clubId: 3, priceTenths: 125, sellingPriceTenths: 125, xp: 8.5, pStart: 0.95, pSub: 0.05),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CandidatePicker(
              availableCandidates: pool,
              maxBudgetTenths: 160,
              onCandidateSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Select Player'), findsOneWidget);
      expect(find.text('Max: £16.0m'), findsOneWidget);
      expect(find.text('Salah'), findsOneWidget);
    });
  });

  group('StatTile (D14)', () {
    testWidgets('renders standard, positive, and negative variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatTile(label: 'Bank Balance', value: '£1.5m'),
                StatTile(label: 'Net Gain', value: '+3.5 pts', variant: StatTileVariant.positive),
                StatTile(label: 'Hit Cost', value: '-4 pts', variant: StatTileVariant.negative),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bank Balance'), findsOneWidget);
      expect(find.text('£1.5m'), findsOneWidget);
      expect(find.text('+3.5 pts'), findsOneWidget);
      expect(find.text('-4 pts'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });
  });
}
