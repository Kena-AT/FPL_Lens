import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:fpl_lens/features/lineup/screens/heatmap_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class MockHeatmapFplRepository implements FplRepository {
  @override
  Future<Map<String, dynamic>> getProjectionBundle(int gw) async {
    return {
      'gameweek': gw,
      'model_version': 'xp-v1.5.0',
      'inputs_as_of': '2026-10-20T12:00:00Z',
      'players': [
        {
          'fpl_id': 101,
          'fixtures': [
            {
              'fixture_fpl_id': 1000 + gw,
              'expected_points': 6.5,
              'difficulty': 2,
              'p_start': 0.95,
              'availability': 1.0,
              'is_home': true,
              'opponent_short_name': 'AVL',
            }
          ],
        },
        {
          'fpl_id': 102,
          'fixtures': [
            {
              'fixture_fpl_id': 2000 + gw,
              'expected_points': 4.0,
              'difficulty': 4,
              'p_start': 0.85,
              'availability': 0.75,
              'is_home': false,
              'opponent_short_name': 'LIV',
            }
          ],
        },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  FakeSquadNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final List<SquadPlayersTableData> sampleSquad = [
    SquadPlayersTableData(
      id: 1,
      fplId: 101,
      webName: 'Raya',
      position: 'GK',
      teamId: 1,
      teamShortName: 'ARS',
      nowCostTenths: 55,
      purchasePriceTenths: 55,
      sellingPriceTenths: 55,
      priceSource: 'CONFIRM',
      status: 'a',
      chanceOfPlayingNextRound: 100,
      isCaptain: false,
      isViceCaptain: false,
      multiplier: 1,
      positionOrder: 1,
      updatedAt: DateTime(2026, 10, 20),
    ),
    SquadPlayersTableData(
      id: 2,
      fplId: 102,
      webName: 'Saliba',
      position: 'DEF',
      teamId: 1,
      teamShortName: 'ARS',
      nowCostTenths: 60,
      purchasePriceTenths: 60,
      sellingPriceTenths: 60,
      priceSource: 'CONFIRM',
      status: 'd',
      chanceOfPlayingNextRound: 75,
      isCaptain: false,
      isViceCaptain: false,
      multiplier: 1,
      positionOrder: 2,
      updatedAt: DateTime(2026, 10, 20),
    ),
  ];

  Widget buildHeatmapScreen() {
    final fakeSquadNotifier = FakeSquadNotifier(
      SquadState(
        squad: sampleSquad,
        currentGameweek: const GameweekMetadata(id: 9, name: 'Gameweek 9'),
        nextGameweek: const GameweekMetadata(id: 9, name: 'Gameweek 9'),
      ),
    );

    return ProviderScope(
      overrides: [
        fplRepositoryProvider.overrideWithValue(MockHeatmapFplRepository()),
        squadNotifierProvider.overrideWith((ref) => fakeSquadNotifier),
      ],
      child: const MaterialApp(
        home: HeatmapScreen(),
      ),
    );
  }

  group('P21 HeatmapScreen Tests', () {
    testWidgets('Renders heatmap with 5 gameweek columns and squad players', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHeatmapScreen());
      await tester.pumpAndSettle();

      expect(find.text('Heatmap'), findsOneWidget);
      expect(find.text('Squad'), findsOneWidget);
      expect(find.text('All players'), findsOneWidget);
      expect(find.text('Expected points'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Start chance'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);

      expect(find.text('Gameweeks 9 to 13'), findsOneWidget);
      expect(find.text('Higher is better'), findsOneWidget);

      // Check Gameweek headers
      expect(find.text('GW 9'), findsWidgets);
      expect(find.text('GW 10'), findsWidgets);
      expect(find.text('GW 11'), findsWidgets);
      expect(find.text('GW 12'), findsWidgets);
      expect(find.text('GW 13'), findsWidgets);

      // Check position headers & players
      expect(find.text('GOALKEEPERS'), findsOneWidget);
      expect(find.text('Raya'), findsOneWidget);
      expect(find.text('DEFENDERS'), findsOneWidget);
      expect(find.text('Saliba'), findsOneWidget);

      // Check footer note
      expect(
        find.text(
          'Projections are estimates. Blank cells mean no fixture. Dashes mean no projection yet.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Switching metric updates ramp direction', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHeatmapScreen());
      await tester.pumpAndSettle();

      expect(find.text('Higher is better'), findsOneWidget);

      // Select Difficulty
      await tester.tap(find.text('Difficulty'));
      await tester.pumpAndSettle();

      expect(find.text('Lower is better (easier)'), findsOneWidget);
    });

    testWidgets('Toggling list view mode switches view', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHeatmapScreen());
      await tester.pumpAndSettle();

      // Find view list toggle button
      final toggleBtn = find.byTooltip('Switch to List View');
      expect(toggleBtn, findsOneWidget);

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      // In list view, player card has 'Raya (GK)'
      expect(find.text('Raya (GK)'), findsOneWidget);
      expect(find.text('Saliba (DEF)'), findsOneWidget);
    });
  });
}
